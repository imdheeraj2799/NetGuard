package com.app.net_guard

import android.content.Context
import android.net.VpnService

enum class VpnState(val value: String) {
    ACTIVE("active"),
    RESTARTING("restarting"),
    INACTIVE("inactive");

    companion object {
        fun fromValue(value: String): VpnState =
            entries.firstOrNull { it.value.equals(value, ignoreCase = true) } ?: INACTIVE
    }
}

data class VpnStatusData(
    val state: VpnState,
    val blockedCount: Int,
    val reason: String? = null,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "status" to state.value,
        "blockedCount" to blockedCount,
        "reason" to reason,
    )
}

object VpnStatusMonitor {
    @Volatile
    private var currentState: VpnState = VpnState.INACTIVE

    @Volatile
    private var currentReason: String? = null

    @Volatile
    private var currentBlockedCount: Int = 0

    private val listeners = mutableListOf<(VpnStatusData) -> Unit>()

    @Synchronized
    fun update(state: VpnState, blockedCount: Int, reason: String? = null) {
        currentState = state
        currentBlockedCount = blockedCount
        currentReason = reason
        val data = VpnStatusData(state, blockedCount, reason)
        val copy = listeners.toList()
        copy.forEach { it.invoke(data) }
    }

    @Synchronized
    fun addListener(listener: (VpnStatusData) -> Unit) {
        listeners.add(listener)
        listener.invoke(VpnStatusData(currentState, currentBlockedCount, currentReason))
    }

    @Synchronized
    fun removeListener(listener: (VpnStatusData) -> Unit) {
        listeners.remove(listener)
    }

    fun getCurrentStatus(context: Context): VpnStatusData {
        val isServiceRunning = AppBlockerVpnService.isServiceRunning
        val isEstablished = AppBlockerVpnService.isVpnEstablished
        val blockedPackages = AppBlockerVpnService.loadBlockedPackages(context)
        val isPermissionRevoked = VpnService.prepare(context) != null

        val resolvedState = when {
            isServiceRunning && isEstablished -> VpnState.ACTIVE
            isServiceRunning && currentState == VpnState.RESTARTING -> VpnState.RESTARTING
            else -> VpnState.INACTIVE
        }

        val resolvedReason = when {
            isPermissionRevoked && blockedPackages.isNotEmpty() ->
                "VPN permission revoked. Tap to restore protection."
            resolvedState == VpnState.INACTIVE && blockedPackages.isNotEmpty() && !isServiceRunning ->
                currentReason ?: "Firewall is inactive. Tap to restore protection."
            resolvedState == VpnState.RESTARTING ->
                currentReason ?: "Restarting firewall..."
            else -> currentReason
        }

        return VpnStatusData(
            state = resolvedState,
            blockedCount = blockedPackages.size,
            reason = resolvedReason,
        )
    }
}
