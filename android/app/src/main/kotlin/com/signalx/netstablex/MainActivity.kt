package com.signalx.netstablex

import android.content.Context
import android.telephony.CellInfoLte
import android.telephony.CellInfoWcdma
import android.telephony.TelephonyManager
import android.media.ToneGenerator
import android.media.AudioManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Timer
import java.util.TimerTask
import java.net.InetAddress

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.signalx/stabilizer"
    private var timer: Timer? = null
    private val toneGenerator = ToneGenerator(AudioManager.STREAM_SYSTEM, 100)

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    startHeartbeat()
                    result.success("Service Started")
                }
                "stopService" -> {
                    stopHeartbeat()
                    result.success("Service Stopped")
                }
                "getSignalStrength" -> {
                    val signalData = getSignalStrengthAndType()
                    result.success(signalData)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startHeartbeat() {
        if (timer == null) {
            timer = Timer()
            timer?.scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    try {
                        val address = InetAddress.getByName("8.8.8.8")
                        address.isReachable(2000)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }, 0, 5000)
        }
    }

    private fun stopHeartbeat() {
        timer?.cancel()
        timer = null
    }

    private fun getSignalStrengthAndType(): Map<String, Any> {
        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        var dbm = -120
        var networkType = "No Signal"

        try {
            val cellInfoList = telephonyManager.allCellInfo
            if (cellInfoList != null) {
                for (cellInfo in cellInfoList) {
                    if (cellInfo.isRegistered) {
                        if (cellInfo is CellInfoLte) {
                            dbm = cellInfo.cellSignalStrength.dbm
                            networkType = "Hutch 4G"
                            break
                        } else if (cellInfo is CellInfoWcdma) {
                            dbm = cellInfo.cellSignalStrength.dbm
                            networkType = "Hutch 3G"
                            break
                        }
                    }
                }
            }
        } catch (e: SecurityException) {
            networkType = "Permission Denied"
        }

        if (dbm in -90..-70) {
            toneGenerator.startTone(ToneGenerator.TONE_PROP_BEEP, 150)
        }

        return mapOf("dbm" to dbm, "networkType" to networkType)
    }
}