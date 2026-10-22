package com.app.net_guard

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

data class NativeBlockSchedule(
    val id: String,
    val name: String,
    val selectedPackages: Set<String>,
    val recurrenceType: String, // "daily", "weekdays", "custom", "one_time"
    val customDays: Set<Int>,   // 1 = Monday, ..., 7 = Sunday
    val targetDate: String?,    // "yyyy-MM-dd"
    val startTime: String,      // "HH:mm"
    val endTime: String,        // "HH:mm"
    val isEnabled: Boolean,
) {
    companion object {
        private fun parseTimeString(json: JSONObject, timeKey: String, hourKey: String, minuteKey: String): String {
            if (json.has(timeKey) && !json.isNull(timeKey)) {
                val str = json.optString(timeKey, "")
                if (!str.isNullOrBlank()) {
                    return if (str.length >= 5) str.substring(0, 5) else str
                }
            }
            val hour = if (json.has(hourKey)) json.optInt(hourKey, 0) else 0
            val minute = if (json.has(minuteKey)) json.optInt(minuteKey, 0) else 0
            return String.format(Locale.US, "%02d:%02d", hour, minute)
        }

        fun fromJsonObject(json: JSONObject): NativeBlockSchedule {
            val packages = mutableSetOf<String>()
            val packagesArray = if (json.has("selectedPackages")) {
                json.optJSONArray("selectedPackages")
            } else {
                json.optJSONArray("packageNames")
            }
            if (packagesArray != null) {
                val arr = packagesArray
                for (i in 0 until arr.length()) {
                    val pkg = arr.getString(i)
                    if (!pkg.isNullOrBlank()) {
                        packages.add(pkg)
                    }
                }
            }

            val customDaysSet = mutableSetOf<Int>()
            val daysArray = if (json.has("customDays")) {
                json.optJSONArray("customDays")
            } else {
                json.optJSONArray("customDaysOfWeek")
            }
            if (daysArray != null) {
                val arr = daysArray
                for (i in 0 until arr.length()) {
                    val day = arr.getInt(i)
                    if (day > 0) {
                        customDaysSet.add(day)
                    }
                }
            }

            val recurrenceType = json.optString("recurrenceType", json.optString("recurrence", "daily"))

            val startTime = parseTimeString(json, "startTime", "startHour", "startMinute")
            val endTime = parseTimeString(json, "endTime", "endHour", "endMinute")

            val rawTargetDate = if (json.has("targetDate") && !json.isNull("targetDate")) json.optString("targetDate", null) else null
            val targetDate = if (!rawTargetDate.isNullOrBlank()) {
                if (rawTargetDate.length >= 10) rawTargetDate.substring(0, 10) else rawTargetDate
            } else {
                null
            }

            return NativeBlockSchedule(
                id = json.optString("id", ""),
                name = json.optString("name", "Block Schedule"),
                selectedPackages = packages,
                recurrenceType = recurrenceType,
                customDays = customDaysSet,
                targetDate = targetDate,
                startTime = startTime,
                endTime = endTime,
                isEnabled = json.optBoolean("isEnabled", true),
            )
        }
    }
}

object NativeScheduleStore {
    private const val PREFS_NAME = "app_blocker_vpn"
    private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_SCHEDULES_JSON = "app_blocker_schedules_json"
    private const val FLUTTER_KEY_SCHEDULES_JSON = "flutter.app_blocker_schedules_json"
    private const val KEY_MANUAL_PACKAGES = "manual_blocked_packages"
    private const val FLUTTER_KEY_MANUAL_PACKAGES = "flutter.blocked_packages"

    @Synchronized
    fun saveSchedulesJson(context: Context, jsonString: String) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_SCHEDULES_JSON, jsonString)
            .commit()
    }

    @Synchronized
    fun loadSchedulesJson(context: Context): String? {
        val direct = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_SCHEDULES_JSON, null)
        if (!direct.isNullOrBlank()) return direct

        return context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            .getString(FLUTTER_KEY_SCHEDULES_JSON, null)
    }

    fun loadSchedules(context: Context): List<NativeBlockSchedule> {
        val jsonString = loadSchedulesJson(context) ?: return emptyList()
        return try {
            val list = mutableListOf<NativeBlockSchedule>()
            val jsonArray = JSONArray(jsonString)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                list.add(NativeBlockSchedule.fromJsonObject(obj))
            }
            list
        } catch (_: Exception) {
            emptyList()
        }
    }

    @Synchronized
    fun saveManualBlockedPackages(context: Context, packages: Set<String>) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putStringSet(KEY_MANUAL_PACKAGES, packages)
            .commit()
    }

    @Synchronized
    fun loadManualBlockedPackages(context: Context): Set<String> {
        val direct = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getStringSet(KEY_MANUAL_PACKAGES, null)
        if (direct != null) return direct.toSet()

        val flutterSet = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            .getStringSet(FLUTTER_KEY_MANUAL_PACKAGES, null)
        return flutterSet?.toSet() ?: emptySet()
    }
}
