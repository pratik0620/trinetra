package com.example.women_safety_app

import android.Manifest
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter

        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "startAdvertising" -> {
                        val serviceUuidStr = call.argument<String>("serviceUuid") ?: ""
                        val payload = call.argument<String>("payload") ?: ""
                        
                        val success = startRelayAdvertising(serviceUuidStr, payload)
                        result.success(success)
                    }
                    "stopAdvertising" -> {
                        stopRelayAdvertising()
                        result.success(true)
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

    private fun startRelayAdvertising(serviceUuidStr: String, payload: String): Boolean {
        if (!hasBlePermissions()) {
            Log.e("RelayNative", "Missing BLUETOOTH permissions for advertising")
            return false
        }
        
        val adapter = bluetoothAdapter ?: return false
        if (!adapter.isEnabled) {
            Log.e("RelayNative", "Bluetooth is disabled")
            return false
        }

        try {
            val serviceUuid = UUID.fromString(serviceUuidStr)
            
            // Clean up any active advertiser first
            stopRelayAdvertising()
            
            val leAdvertiser = adapter.bluetoothLeAdvertiser
            if (leAdvertiser == null) {
                Log.e("RelayNative", "BLE Advertising not supported on this device")
                return false
            }
            advertiser = leAdvertiser
            
            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
                .setConnectable(false) // Connectionless beacon
                .setTimeout(0) // Advertise indefinitely
                .build()
                
            val data = AdvertiseData.Builder()
                .setIncludeDeviceName(false)
                .setIncludeTxPowerLevel(false)
                .addServiceUuid(ParcelUuid(serviceUuid))
                .build()

            // To maximize payload size, put the manufacturer data in the Scan Response
            val scanResponse = AdvertiseData.Builder()
                .addManufacturerData(0xFFFF, payload.toByteArray(StandardCharsets.UTF_8))
                .build()
                
            val callback = object : AdvertiseCallback() {
                override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                    super.onStartSuccess(settingsInEffect)
                    Log.d("RelayNative", "BLE Advertising started successfully for payload: $payload")
                }
                
                override fun onStartFailure(errorCode: Int) {
                    super.onStartFailure(errorCode)
                    Log.e("RelayNative", "BLE Advertising failed with code: $errorCode")
                }
            }
            advertiseCallback = callback
            
            leAdvertiser.startAdvertising(settings, data, scanResponse, callback)
            return true
        } catch (e: Exception) {
            Log.e("RelayNative", "Failed to start BLE relay advertising", e)
            stopRelayAdvertising()
            return false
        }
    }

    private fun stopRelayAdvertising() {
        try {
            if (advertiser != null && advertiseCallback != null) {
                if (hasBlePermissions()) {
                    advertiser?.stopAdvertising(advertiseCallback)
                }
            }
        } catch (e: Exception) {
            Log.e("RelayNative", "Error stopping advertising", e)
        } finally {
            advertiser = null
            advertiseCallback = null
        }
    }
}
