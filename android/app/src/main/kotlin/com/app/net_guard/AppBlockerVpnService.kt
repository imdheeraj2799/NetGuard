package com.app.net_guard

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.nio.ByteBuffer
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Future

/**
 * A local loopback VPN service supporting:
 * 1. Package-level traffic restriction (sinkhole).
 * 2. Domain/URL-level filtering via local DNS interception on UDP port 53.
 */
class AppBlockerVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var tunInput: FileInputStream? = null
    private var tunOutput: FileOutputStream? = null
    private var drainFuture: Future<*>? = null
    private val packetExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val dnsWorkerPool: ExecutorService = Executors.newFixedThreadPool(4)

    @Volatile
    private var isDraining = false

    @Volatile
    private var currentBlacklist: Set<String> = emptySet()

    @Volatile
    private var currentBlockedPackages: Set<String> = emptySet()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                try {
                    startForeground(NOTIFICATION_ID, createNotification(0, 0))
                } catch (_: Exception) {
                }
                stopVpn()
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_UPDATE_DNS_BLACKLIST -> {
                val newBlacklist = intent.getStringArrayListExtra(EXTRA_DNS_BLACKLIST)?.toSet()
                    ?: loadDnsBlacklist(this)
                currentBlacklist = newBlacklist
                saveDnsBlacklist(this, newBlacklist)
                val blockedPackages = loadBlockedPackages(this)
                currentBlockedPackages = blockedPackages

                if (blockedPackages.isEmpty() && newBlacklist.isEmpty()) {
                    try {
                        startForeground(NOTIFICATION_ID, createNotification(0, 0))
                    } catch (_: Exception) {
                    }
                    stopVpn()
                    stopSelf()
                    return START_NOT_STICKY
                }

                if (vpnInterface == null) {
                    configureVpn(blockedPackages, newBlacklist)
                }
                updateNotification()
            }
            ACTION_UPDATE_CUSTOM_DNS -> {
                val newDns = intent?.getStringExtra(EXTRA_CUSTOM_DNS) ?: UPSTREAM_DNS_SERVER
                saveCustomDnsServer(this, newDns)
                val blockedPackages = loadBlockedPackages(this)
                val blacklist = loadDnsBlacklist(this)
                if (vpnInterface != null) {
                    configureVpn(blockedPackages, blacklist)
                }
            }
            ACTION_START, ACTION_UPDATE, null -> {
                val blockedPackages = intent?.getStringArrayListExtra(EXTRA_BLOCKED_PACKAGES)
                    ?.toSet()
                    ?: loadBlockedPackages(this)
                val blacklist = intent?.getStringArrayListExtra(EXTRA_DNS_BLACKLIST)
                    ?.toSet()
                    ?: loadDnsBlacklist(this)

                currentBlockedPackages = blockedPackages
                currentBlacklist = blacklist

                if (blockedPackages.isEmpty() && blacklist.isEmpty()) {
                    try {
                        startForeground(NOTIFICATION_ID, createNotification(0, 0))
                    } catch (_: Exception) {
                    }
                    stopVpn()
                    stopSelf()
                    return START_NOT_STICKY
                }

                saveBlockedPackages(this, blockedPackages)
                saveDnsBlacklist(this, blacklist)
                try {
                    startForeground(NOTIFICATION_ID, createNotification(blockedPackages.size, blacklist.size))
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start foreground notification: ${e.message}")
                }
                try {
                    configureVpn(blockedPackages, blacklist)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to configure VPN: ${e.message}")
                }
            }
        }
        return START_STICKY
    }

    override fun onRevoke() {
        stopVpn()
        stopSelf()
        super.onRevoke()
    }

    override fun onDestroy() {
        stopVpn()
        packetExecutor.shutdownNow()
        dnsWorkerPool.shutdownNow()
        super.onDestroy()
    }

    private fun configureVpn(blockedPackages: Set<String>, dnsBlacklist: Set<String>) {
        stopVpn()

        val builder = Builder()
            .setSession(getString(R.string.app_name))
            .setMtu(1500)
            .addAddress(IPV4_ADDRESS, 32)
            .addAddress(IPV6_ADDRESS, 128)

        if (dnsBlacklist.isNotEmpty()) {
            // In DNS filtering mode, NetGuard itself is disallowed so upstream DNS queries don't loop into the TUN interface
            try {
                builder.addDisallowedApplication(packageName)
            } catch (_: Exception) {
            }
            builder.addDnsServer(LOCAL_DNS_SERVER)
            builder.addRoute(LOCAL_DNS_SERVER, 32)
        } else if (blockedPackages.isNotEmpty()) {
            // In package sinkhole mode, route traffic ONLY for blocked packages.
            // DO NOT call addDisallowedApplication here because addAllowedApplication and
            // addDisallowedApplication are mutually exclusive in Android VpnService.Builder
            // and calling both throws java.lang.UnsupportedOperationException.
            builder.addRoute("0.0.0.0", 0)
            builder.addRoute("::", 0)
            blockedPackages.forEach { pkg ->
                try {
                    builder.addAllowedApplication(pkg)
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to add allowed application $pkg: ${e.message}")
                }
            }
        } else {
            stopSelf()
            return
        }

        val descriptor = try {
            builder.establish()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to establish VPN interface: ${e.message}")
            null
        }

        if (descriptor == null) {
            stopSelf()
            return
        }

        vpnInterface = descriptor
        val input = FileInputStream(descriptor.fileDescriptor)
        val output = FileOutputStream(descriptor.fileDescriptor)
        tunInput = input
        tunOutput = output
        isDraining = true
        drainFuture = packetExecutor.submit {
            processTunPackets(input, output, descriptor)
        }
    }

    private fun processTunPackets(
        input: FileInputStream,
        output: FileOutputStream,
        descriptor: ParcelFileDescriptor,
    ) {
        val buffer = ByteArray(MAX_PACKET_SIZE)
        try {
            while (isDraining && vpnInterface === descriptor) {
                val length = input.read(buffer)
                if (length <= 0) break

                handlePacket(buffer, length, output)
            }
        } catch (_: IOException) {
            // Expected when the TUN descriptor is closed
        }
    }

    private fun handlePacket(packet: ByteArray, length: Int, output: FileOutputStream) {
        // Only inspect IPv4
        val version = (packet[0].toInt() and 0xF0) ushr 4
        if (version != 4 || length < 28) return

        val ihl = (packet[0].toInt() and 0x0F) * 4
        val protocol = packet[9].toInt() and 0xFF

        // Protocol 17 = UDP
        if (protocol != 17 || length < ihl + 8) return

        val srcPort = ((packet[ihl].toInt() and 0xFF) shl 8) or (packet[ihl + 1].toInt() and 0xFF)
        val dstPort = ((packet[ihl + 2].toInt() and 0xFF) shl 8) or (packet[ihl + 3].toInt() and 0xFF)
        val udpLen = ((packet[ihl + 4].toInt() and 0xFF) shl 8) or (packet[ihl + 5].toInt() and 0xFF)

        // Destination port 53 = DNS query
        if (dstPort == 53 && length >= ihl + 8 + 12) {
            val dnsOffset = ihl + 8
            val dnsPayloadLen = udpLen - 8
            if (dnsPayloadLen < 12 || dnsOffset + dnsPayloadLen > length) return

            val qnameInfo = parseQName(packet, dnsOffset + 12, dnsOffset + dnsPayloadLen)
            if (qnameInfo != null) {
                val qname = qnameInfo.first
                val questionLen = qnameInfo.second + 4 // QNAME bytes + QTYPE (2) + QCLASS (2)

                if (isDomainBlocked(qname, currentBlacklist)) {
                    Log.i(TAG, "DNS Blocked: $qname -> Synthesizing NXDOMAIN")
                    synthesizeNxDomainResponse(packet, ihl, srcPort, dstPort, dnsOffset, questionLen, output)
                    return
                }
            }

            // If not blocked, forward to upstream DNS asynchronously
            val packetCopy = packet.copyOf(length)
            dnsWorkerPool.submit {
                forwardDnsQuery(packetCopy, ihl, srcPort, dstPort, dnsOffset, dnsPayloadLen, output)
            }
        }
    }

    private fun parseQName(buffer: ByteArray, startOffset: Int, maxOffset: Int): Pair<String, Int>? {
        var offset = startOffset
        val sb = StringBuilder()
        var totalBytes = 0

        while (offset < maxOffset) {
            val len = buffer[offset].toInt() and 0xFF
            totalBytes++
            offset++

            if (len == 0) {
                break
            }
            if ((len and 0xC0) == 0xC0) {
                // Compression pointer
                totalBytes++
                break
            }
            if (offset + len > maxOffset) return null

            for (i in 0 until len) {
                sb.append(buffer[offset + i].toInt().toChar())
            }
            offset += len
            totalBytes += len

            if (offset < maxOffset && (buffer[offset].toInt() and 0xFF) != 0) {
                sb.append('.')
            }
        }

        return if (sb.isNotEmpty()) Pair(sb.toString(), totalBytes) else null
    }

    private fun isDomainBlocked(qname: String, blacklist: Set<String>): Boolean {
        val target = qname.trim().trimEnd('.').lowercase()
        for (pattern in blacklist) {
            val cleaned = pattern.trim().trimEnd('.').lowercase()
            if (cleaned.startsWith("*.")) {
                val suffix = cleaned.substring(2)
                if (target == suffix || target.endsWith(".$suffix")) {
                    return true
                }
            } else {
                if (target == cleaned || target.endsWith(".$cleaned")) {
                    return true
                }
            }
        }
        return false
    }

    private fun synthesizeNxDomainResponse(
        reqPacket: ByteArray,
        ihl: Int,
        srcPort: Int,
        dstPort: Int,
        dnsOffset: Int,
        questionLen: Int,
        output: FileOutputStream,
    ) {
        val dnsRespLen = 12 + questionLen
        val totalLen = 20 + 8 + dnsRespLen
        val resp = ByteArray(totalLen)
        val bb = ByteBuffer.wrap(resp)

        // 1. IPv4 Header (20 bytes)
        bb.put(0x45.toByte()) // Version 4, IHL 5
        bb.put(0x00.toByte()) // DSCP / ECN
        bb.putShort(totalLen.toShort()) // Total Length
        bb.putShort(0.toShort()) // Identification
        bb.putShort(0x4000.toShort()) // Flags: Don't Fragment
        bb.put(64.toByte()) // TTL
        bb.put(17.toByte()) // Protocol: UDP
        bb.putShort(0.toShort()) // Checksum placeholder
        // Source IP = original destination IP
        bb.put(reqPacket, 16, 4)
        // Destination IP = original source IP
        bb.put(reqPacket, 12, 4)

        // Calculate and set IPv4 Checksum
        val ipChecksum = calculateIpChecksum(resp, 0, 20)
        resp[10] = ((ipChecksum.toInt() ushr 8) and 0xFF).toByte()
        resp[11] = (ipChecksum.toInt() and 0xFF).toByte()

        // 2. UDP Header (8 bytes)
        bb.position(20)
        bb.putShort(dstPort.toShort()) // Source Port (53)
        bb.putShort(srcPort.toShort()) // Destination Port
        bb.putShort((8 + dnsRespLen).toShort()) // Length
        bb.putShort(0.toShort()) // Checksum (0 = omitted for IPv4 UDP)

        // 3. DNS Header (12 bytes)
        // Transaction ID
        bb.put(reqPacket, dnsOffset, 2)
        // Flags: 0x8183 -> Response (1), Opcode (0), AA (0), TC (0), RD (1), RA (1), RCODE (3 = NXDOMAIN)
        bb.putShort(0x8183.toShort())
        // QDCOUNT = 1
        bb.putShort(1.toShort())
        // ANCOUNT = 0, NSCOUNT = 0, ARCOUNT = 0
        bb.putShort(0.toShort())
        bb.putShort(0.toShort())
        bb.putShort(0.toShort())

        // 4. Question Section (copied verbatim from request)
        bb.put(reqPacket, dnsOffset + 12, questionLen)

        try {
            synchronized(output) {
                output.write(resp)
                output.flush()
            }
        } catch (_: IOException) {
        }
    }

    private fun forwardDnsQuery(
        reqPacket: ByteArray,
        ihl: Int,
        srcPort: Int,
        dstPort: Int,
        dnsOffset: Int,
        dnsPayloadLen: Int,
        output: FileOutputStream,
    ) {
        var socket: DatagramSocket? = null
        try {
            socket = DatagramSocket()
            protect(socket)
            socket.soTimeout = 3000

            val dnsQuery = reqPacket.copyOfRange(dnsOffset, dnsOffset + dnsPayloadLen)
            val dnsServerIp = loadCustomDnsServer(this)
            val upstreamAddress = InetAddress.getByName(dnsServerIp)
            val sendPacket = DatagramPacket(dnsQuery, dnsQuery.size, upstreamAddress, 53)
            socket.send(sendPacket)

            val recvBuffer = ByteArray(1500)
            val recvPacket = DatagramPacket(recvBuffer, recvBuffer.size)
            socket.receive(recvPacket)

            val dnsRespLen = recvPacket.length
            val totalLen = 20 + 8 + dnsRespLen
            val resp = ByteArray(totalLen)
            val bb = ByteBuffer.wrap(resp)

            // IPv4 Header
            bb.put(0x45.toByte())
            bb.put(0x00.toByte())
            bb.putShort(totalLen.toShort())
            bb.putShort(0.toShort())
            bb.putShort(0x4000.toShort())
            bb.put(64.toByte())
            bb.put(17.toByte())
            bb.putShort(0.toShort())
            bb.put(reqPacket, 16, 4) // Source IP = original destination
            bb.put(reqPacket, 12, 4) // Destination IP = original source

            val ipChecksum = calculateIpChecksum(resp, 0, 20)
            resp[10] = ((ipChecksum.toInt() ushr 8) and 0xFF).toByte()
            resp[11] = (ipChecksum.toInt() and 0xFF).toByte()

            // UDP Header
            bb.position(20)
            bb.putShort(dstPort.toShort()) // Source Port (53)
            bb.putShort(srcPort.toShort()) // Destination Port
            bb.putShort((8 + dnsRespLen).toShort())
            bb.putShort(0.toShort())

            // DNS Payload
            bb.put(recvPacket.data, 0, dnsRespLen)

            synchronized(output) {
                output.write(resp)
                output.flush()
            }
        } catch (_: Exception) {
            // If forwarding fails, synthesize NXDOMAIN so client doesn't stall
            synthesizeNxDomainResponse(reqPacket, ihl, srcPort, dstPort, dnsOffset, dnsPayloadLen - 12, output)
        } finally {
            socket?.close()
        }
    }

    private fun calculateIpChecksum(data: ByteArray, offset: Int, length: Int): Short {
        var sum = 0
        var i = offset
        while (i < offset + length) {
            val word = ((data[i].toInt() and 0xFF) shl 8) or (data[i + 1].toInt() and 0xFF)
            sum += word
            i += 2
        }
        while ((sum ushr 16) != 0) {
            sum = (sum and 0xFFFF) + (sum ushr 16)
        }
        return sum.inv().toShort()
    }

    private fun stopVpn() {
        isDraining = false
        drainFuture?.cancel(true)
        drainFuture = null
        try {
            tunInput?.close()
        } catch (_: IOException) {
        }
        tunInput = null
        try {
            tunOutput?.close()
        } catch (_: IOException) {
        }
        tunOutput = null
        try {
            vpnInterface?.close()
        } catch (_: IOException) {
        }
        vpnInterface = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun updateNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(
            NOTIFICATION_ID,
            createNotification(currentBlockedPackages.size, currentBlacklist.size),
        )
    }

    private fun createNotification(blockedAppsCount: Int, blockedDomainsCount: Int): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    getString(R.string.vpn_notification_channel_name),
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = getString(R.string.vpn_notification_channel_description)
                    setShowBadge(false)
                },
            )
        }
        val openAppIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notificationBuilder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        val summaryText = when {
            blockedAppsCount > 0 && blockedDomainsCount > 0 ->
                "$blockedAppsCount apps, $blockedDomainsCount domains restricted"
            blockedDomainsCount > 0 ->
                "$blockedDomainsCount domains restricted"
            else ->
                getString(R.string.vpn_notification_text, blockedAppsCount)
        }

        return notificationBuilder
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setContentTitle(getString(R.string.vpn_notification_title))
            .setContentText(summaryText)
            .setContentIntent(openAppIntent)
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val TAG = "AppBlockerVpnService"
        const val ACTION_START = "com.app.net_guard.action.START_VPN"
        const val ACTION_STOP = "com.app.net_guard.action.STOP_VPN"
        const val ACTION_UPDATE = "com.app.net_guard.action.UPDATE_BLOCKED_PACKAGES"
        const val ACTION_UPDATE_DNS_BLACKLIST = "com.app.net_guard.action.UPDATE_DNS_BLACKLIST"
        const val ACTION_UPDATE_CUSTOM_DNS = "com.app.net_guard.action.UPDATE_CUSTOM_DNS"

        const val EXTRA_BLOCKED_PACKAGES = "blocked_packages"
        const val EXTRA_DNS_BLACKLIST = "dns_blacklist"
        const val EXTRA_CUSTOM_DNS = "custom_dns"

        private const val PREFERENCES_NAME = "app_blocker_vpn"
        private const val BLOCKED_PACKAGES_KEY = "blocked_packages"
        private const val DNS_BLACKLIST_KEY = "dns_blacklist"
        private const val CUSTOM_DNS_KEY = "custom_dns"
        private const val NOTIFICATION_ID = 1001
        private const val NOTIFICATION_CHANNEL_ID = "app_blocker_vpn"
        private const val IPV4_ADDRESS = "10.120.0.2"
        private const val IPV6_ADDRESS = "fd00:120::2"
        private const val LOCAL_DNS_SERVER = "10.120.0.53"
        private const val UPSTREAM_DNS_SERVER = "1.1.1.1"
        private const val MAX_PACKET_SIZE = 32767

        fun saveBlockedPackages(context: Context, packages: Set<String>) {
            context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .edit()
                .putStringSet(BLOCKED_PACKAGES_KEY, packages)
                .apply()
        }

        fun loadBlockedPackages(context: Context): Set<String> =
            context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .getStringSet(BLOCKED_PACKAGES_KEY, emptySet())
                ?.toSet()
                ?: emptySet()

        fun saveDnsBlacklist(context: Context, domains: Set<String>) {
            context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .edit()
                .putStringSet(DNS_BLACKLIST_KEY, domains)
                .apply()
        }

        fun loadDnsBlacklist(context: Context): Set<String> =
            context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .getStringSet(DNS_BLACKLIST_KEY, emptySet())
                ?.toSet()
                ?: emptySet()

        fun saveCustomDnsServer(context: Context, dnsServer: String) {
            context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(CUSTOM_DNS_KEY, dnsServer)
                .apply()
        }

        fun loadCustomDnsServer(context: Context): String =
            context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .getString(CUSTOM_DNS_KEY, UPSTREAM_DNS_SERVER)
                ?: UPSTREAM_DNS_SERVER
    }
}
