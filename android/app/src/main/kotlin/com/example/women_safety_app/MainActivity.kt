package com.example.women_safety_app

import android.Manifest
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.women_safety_app/relay"
    private var bluetoothManager: BluetoothManager? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var advertiser: BluetoothLeAdvertiser? = null
    private var advertiseCallback: AdvertiseCallback? = null
    
    private var pendingResult: MethodChannel.Result? = null
    private var timeoutHandler: Handler? = null
    private var timeoutRunnable: Runnable? = null
    
    private var isAdvertising = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter
        timeoutHandler = Handler(Looper.getMainLooper())

        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "startAdvertising" -> {
                        val serviceUuidStr = call.argument<String>("serviceUuid") ?: ""
                        val payload = call.argument<String>("payload") ?: ""
                        
                        startRelayAdvertising(serviceUuidStr, payload, result)
                    }
                    "stopAdvertising" -> {
                        stopRelayAdvertising()
                        result.success(true)
                    }
                    "isAdvertising" -> {
                        result.success(isAdvertising)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun hasBlePermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val adv = ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_ADVERTISE)
            val conn = ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
            return adv == PackageManager.PERMISSION_GRANTED && conn == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    private fun decodeAdvertiseErrorCode(errorCode: Int): String {
        return when (errorCode) {
            AdvertiseCallback.ADVERTISE_FAILED_ALREADY_STARTED -> "ADVERTISE_FAILED_ALREADY_STARTED"
            AdvertiseCallback.ADVERTISE_FAILED_DATA_TOO_LARGE -> "ADVERTISE_FAILED_DATA_TOO_LARGE"
            AdvertiseCallback.ADVERTISE_FAILED_FEATURE_UNSUPPORTED -> "ADVERTISE_FAILED_FEATURE_UNSUPPORTED"
            AdvertiseCallback.ADVERTISE_FAILED_INTERNAL_ERROR -> "ADVERTISE_FAILED_INTERNAL_ERROR"
            AdvertiseCallback.ADVERTISE_FAILED_TOO_MANY_ADVERTISERS -> "ADVERTISE_FAILED_TOO_MANY_ADVERTISERS"
            else -> "UNKNOWN_ADVERTISE_ERROR"
        }
    }

    private fun startRelayAdvertising(serviceUuidStr: String, payload: String, result: MethodChannel.Result) {
        // Resolve any previous pending result before starting a new one
        pendingResult?.success(false)
        pendingResult = result

        // Cancel any active timeout
        timeoutRunnable?.let { timeoutHandler?.removeCallbacks(it) }

        Log.d("RelayNative", "[Relay] Starting advertising")

        val btOn = bluetoothAdapter?.isEnabled == true
        val advertiserAvail = bluetoothAdapter?.bluetoothLeAdvertiser != null
        val advPermGranted = hasBlePermissions()

        Log.d("RelayNative", "[Relay] Bluetooth enabled: $btOn")
        Log.d("RelayNative", "[Relay] Advertiser available: $advertiserAvail")
        Log.d("RelayNative", "[Relay] Advertise permission: ${if (advPermGranted) "granted" else "denied"}")
        Log.d("RelayNative", "[Relay] Service UUID: $serviceUuidStr")
        Log.d("RelayNative", "[Relay] Payload length: ${payload.length}")

        if (!advPermGranted) {
            Log.e("RelayNative", "[Relay] Advertising failed due to missing permission")
            pendingResult?.success(false)
            pendingResult = null
            return
        }

        val adapter = bluetoothAdapter
        if (adapter == null || !btOn) {
            Log.e("RelayNative", "[Relay] Advertising failed: Bluetooth is off or unavailable")
            pendingResult?.success(false)
            pendingResult = null
            return
        }

        try {
            val serviceUuid = UUID.fromString(serviceUuidStr)
            
            // Clean up any active advertising session first
            stopRelayAdvertisingInternal()
            
            val leAdvertiser = adapter.bluetoothLeAdvertiser
            if (leAdvertiser == null) {
                Log.e("RelayNative", "[Relay] Advertising failed: BLE Advertiser not supported")
                pendingResult?.success(false)
                pendingResult = null
                return
            }
            advertiser = leAdvertiser

            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
                .setConnectable(true) // Connectable to support scan response on all BLE controllers
                .setTimeout(0) // No hardware timeout, managed in Dart/Kotlin
                .build()
                
            val data = AdvertiseData.Builder()
                .setIncludeDeviceName(false)
                .setIncludeTxPowerLevel(false)
                .addServiceUuid(ParcelUuid(serviceUuid))
                .build()

            val scanResponse = AdvertiseData.Builder()
                .addManufacturerData(0xFFFF, payload.toByteArray(StandardCharsets.UTF_8))
                .build()
                
            val callback = object : AdvertiseCallback() {
                override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                    super.onStartSuccess(settingsInEffect)
                    Log.d("RelayNative", "[Relay] Advertising started successfully")
                    isAdvertising = true
                    
                    // Cancel timeout and complete result on UI thread
                    runOnUiThread {
                        timeoutRunnable?.let { timeoutHandler?.removeCallbacks(it) }
                        pendingResult?.success(true)
                        pendingResult = null
                    }
                }
                
                override fun onStartFailure(errorCode: Int) {
                    super.onStartFailure(errorCode)
                    val errorName = decodeAdvertiseErrorCode(errorCode)
                    Log.e("RelayNative", "[Relay] Advertising failed")
                    Log.e("RelayNative", "[Relay] Error code: $errorCode")
                    Log.e("RelayNative", "[Relay] Error name: $errorName")
                    isAdvertising = false
                    
                    // Cancel timeout and complete result on UI thread
                    runOnUiThread {
                        timeoutRunnable?.let { timeoutHandler?.removeCallbacks(it) }
                        pendingResult?.success(false)
                        pendingResult = null
                    }
                }
            }
            advertiseCallback = callback

            // 5-second startup timeout safeguard
            val runnable = Runnable {
                Log.e("RelayNative", "[Relay] Advertising failed")
                Log.e("RelayNative", "[Relay] Error code: -1")
                Log.e("RelayNative", "[Relay] Error name: ADVERTISE_FAILED_TIMEOUT (Startup timed out)")
                stopRelayAdvertisingInternal()
                
                pendingResult?.success(false)
                pendingResult = null
            }
            timeoutRunnable = runnable
            timeoutHandler?.postDelayed(runnable, 5000)
            
            Log.d("RelayNative", "[Relay] Calling BluetoothLeAdvertiser.startAdvertising()")
            leAdvertiser.startAdvertising(settings, data, scanResponse, callback)

        } catch (e: Exception) {
            Log.e("RelayNative", "[Relay] Advertising failed")
            Log.e("RelayNative", "[Relay] Error code: -2")
            Log.e("RelayNative", "[Relay] Error name: EXCEPTION (${e.message})")
            stopRelayAdvertisingInternal()
            
            pendingResult?.success(false)
            pendingResult = null
        }
    }

    private fun stopRelayAdvertisingInternal() {
        try {
            if (advertiser != null && advertiseCallback != null) {
                if (hasBlePermissions()) {
                    advertiser?.stopAdvertising(advertiseCallback)
                }
            }
        } catch (e: Exception) {
            Log.e("RelayNative", "Error stopping advertising natively: ${e.message}")
        } finally {
            advertiser = null
            advertiseCallback = null
            isAdvertising = false
        }
    }

    private fun stopRelayAdvertising() {
        timeoutRunnable?.let { timeoutHandler?.removeCallbacks(it) }
        stopRelayAdvertisingInternal()
    }
}
