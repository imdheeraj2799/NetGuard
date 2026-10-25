package com.app.net_guard

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

data class NativeTemporaryPause(
    val id: String,
    val packageName: String,
    val appName: String,
    val pauseUntilMillis: Long,
) {
    fun isExpired(nowMillis: Long): Boolean = nowMillis >= pauseUntilMillis

    companion object {
        fun fromJsonObject(json: JSONObject): NativeTemporaryPause? {
            val id = json.optString("id", "")
            val packageName = json.optString("packageName", "")
            if (packageName.isBlank()) return null
            val appName = json.optString("appName", packageName)
            val pauseUntilMillis = if (json.has("pauseUntilMillis")) {
                json.optLong("pauseUntilMillis", 0L)
            } else if (json.has("pauseUntil")) {
                try {
                    java.time.Instant.parse(json.getString("pauseUntil")).toEpochMilli()
                } catch (_: Exception) {
                    0L
                }
            } else {
                0L
            }
            return NativeTemporaryPause(
                id = id,
                packageName = packageName,
                appName = appName,
                pauseUntilMillis = pauseUntilMillis,
            )
        }
    }
}

object NativeTemporaryPauseStore {
    private const val TAG = "NativePauseStore"
    private const val PREFS_NAME = "app_blocker_vpn"
    private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_PAUSES_JSON = "temporary_pauses_json"
    private const val FLUTTER_KEY_PAUSES_JSON = "flutter.temporary_pauses_json"

    @Synchronized
    fun savePausesJson(context: Context, jsonString: String) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_PAUSES_JSON, jsonString)
            .commit()
    }

    @Synchronized
    fun loadPausesJson(context: Context): String? {
        val direct = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_PAUSES_JSON, null)
        if (!direct.isNullOrBlank()) return direct

        return context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            .getString(FLUTTER_KEY_PAUSES_JSON, null)
    }

    @Synchronized
    fun loadPauses(context: Context): List<NativeTemporaryPause> {
        val json = loadPausesJson(context) ?: return emptyList()
        return try {
            val list = mutableListOf<NativeTemporaryPause>()
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val item = NativeTemporaryPause.fromJsonObject(array.getJSONObject(i))
                if (item != null) {
                    list.add(item)
                }
            }
            list
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse pauses json: ${e.message}")
            emptyList()
        }
    }

    @Synchronized
    fun getActivePausedPackages(context: Context, nowMillis: Long): Set<String> {
        val pauses = loadPauses(context)
        val active = pauses.filter { !it.isExpired(nowMillis) }.map { it.packageName }
        return active.toSet()
    }

    @Synchronized
    fun getEarliestExpiryMillis(context: Context, nowMillis: Long): Long? {
        val pauses = loadPauses(context)
        val upcoming = pauses.filter { !it.isExpired(nowMillis) }.map { it.pauseUntilMillis }
        return if (upcoming.isNotEmpty()) upcoming.minOrNull() else null
    }

    @Synchronized
    fun pruneExpired(context: Context, nowMillis: Long): List<NativeTemporaryPause> {
        val pauses = loadPauses(context)
        val active = pauses.filter { !it.isExpired(nowMillis) }
        val expired = pauses.filter { it.isExpired(nowMillis) }
        if (expired.isNotEmpty()) {
            val array = JSONArray()
            active.forEach { pause ->
                val obj = JSONObject().apply {
                    put("id", pause.id)
                    put("packageName", pause.packageName)
                    put("appName", pause.appName)
                    put("pauseUntilMillis", pause.pauseUntilMillis)
                }
                array.put(obj)
            }
            savePausesJson(context, array.toString())
        }
        return expired
    }
}
