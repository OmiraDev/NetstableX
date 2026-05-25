package com.signalx.netstablex

import android.content.Context
import android.os.Build
import android.telephony.PhoneStateListener
import android.telephony.SignalStrength
import android.telephony.TelephonyManager
import android.telephony.CellInfo
import android.telephony.CellInfoLte
import android.telephony.CellInfoWcdma
import android.telephony.CellInfoGsm
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
    
    private var latestDbm = -120
    private var telephonyManager: TelephonyManager? = null
    private var phoneStateListener: PhoneStateListener? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        startListeningToSignal()

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
                "openRadioSettings" -> {
                    try {
                        val intent = android.content.Intent(android.content.Intent.ACTION_MAIN)
                        intent.setClassName("com.android.settings", "com.android.settings.RadioInfo")
                        startActivity(intent)
                        result.success("Opened")
                    } catch (e: Exception) {
                        val intent = android.content.Intent(android.provider.Settings.ACTION_WIRELESS_SETTINGS)
                        startActivity(intent)
                        result.success("Opened Alternative")
                    }
                }
                "getSignalStrength" -> {
                    val provider = call.argument<String>("provider") ?: "Mobile"
                    val signalData = getSignalDataMap(provider)
                    result.success(signalData)
                }
                
                "getCarrierName" -> {
                    try {
                        var carrierName = telephonyManager?.networkOperatorName
                        if (carrierName.isNullOrEmpty()) {
                            carrierName = telephonyManager?.simOperatorName
                        }
                        result.success(carrierName ?: "Unknown")
                    } catch (e: Exception) {
                        result.success("Unknown")
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startListeningToSignal() {
        try {
            phoneStateListener = object : PhoneStateListener() {
                override fun onSignalStrengthsChanged(signalStrength: SignalStrength?) {
                    super.onSignalStrengthsChanged(signalStrength)
                    if (signalStrength != null) {
                        var dbmVal = -120
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            for (strength in signalStrength.cellSignalStrengths) {
                                val d = strength.dbm
                                if (d != java.lang.Integer.MAX_VALUE && d < 0) {
                                    dbmVal = d
                                    break
                                }
                            }
                        }
                        
                        if (dbmVal == -120) {
                            try {
                                val methods = signalStrength.javaClass.methods
                                for (method in methods) {
                                    if (method.name == "getLteDbm" || method.name == "getWcdmaDbm" || method.name == "getGsmDbm" || method.name == "getDbm") {
                                        val value = method.invoke(signalStrength) as Int
                                        if (value != java.lang.Integer.MAX_VALUE && value < 0 && value != -120) {
                                            dbmVal = value
                                            break
                                        }
                                    }
                                }
                            } catch (e: Exception) {}
                        }
                        
                        if (dbmVal == -120) {
                            val raw = signalStrength.toString()
                            val pattern = java.util.regex.Pattern.compile("[-_a-zA-Z]*dbm[:= ]*(-?\\d+)", java.util.regex.Pattern.CASE_INSENSITIVE)
                            val matcher = pattern.matcher(raw)
                            while (matcher.find()) {
                                val parsed = matcher.group(1)?.toIntOrNull()
                                if (parsed != null && parsed < 0 && parsed != -120) {
                                    dbmVal = parsed
                                    break
                                }
                            }
                        }
                        
                        if (dbmVal != -120) {
                            latestDbm = dbmVal
                        }
                    }
                }
            }
            telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_SIGNAL_STRENGTHS)
        } catch (e: Exception) {}
    }

    private fun getSignalDataMap(provider: String): Map<String, Any> {
        var networkType = "$provider Connected"
        
        if (latestDbm == -120) {
            try {
                val cellInfoList = telephonyManager?.allCellInfo
                if (!cellInfoList.isNullOrEmpty()) {
                    for (cellInfo in cellInfoList) {
                        if (cellInfo.isRegistered) {
                            val currentDbm = when (cellInfo) {
                                is CellInfoLte -> cellInfo.cellSignalStrength.dbm
                                is CellInfoWcdma -> cellInfo.cellSignalStrength.dbm
                                is CellInfoGsm -> cellInfo.cellSignalStrength.dbm
                                else -> java.lang.Integer.MAX_VALUE
                            }
                            if (currentDbm != java.lang.Integer.MAX_VALUE && currentDbm < 0) {
                                latestDbm = currentDbm
                                break
                            }
                        }
                    }
                }
            } catch (e: Exception) {}
        }

        try {
            val activeNetworkType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                telephonyManager?.dataNetworkType ?: 0
            } else {
                telephonyManager?.networkType ?: 0
            }

            val gen = when (activeNetworkType) {
                13 -> "4G"
                3, 8, 9, 10, 15 -> "3G"
                1, 2, 4, 7, 11 -> "2G"
                20 -> "5G"
                else -> ""
            }

            if (gen.isNotEmpty()) {
                networkType = "$provider $gen"
            }
        } catch (e: Exception) {
            networkType = "$provider Mobile"
        }

        if (latestDbm in -90..-70) {
            toneGenerator.startTone(ToneGenerator.TONE_PROP_BEEP, 150)
        }

        return mapOf("dbm" to latestDbm, "networkType" to networkType)
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
    
    override fun onDestroy() {
        try {
            telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_NONE)
        } catch (e: Exception) {}
        super.onDestroy()
    }
}