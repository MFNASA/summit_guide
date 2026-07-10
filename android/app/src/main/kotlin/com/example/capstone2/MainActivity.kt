// android/app/src/main/kotlin/.../MainActivity.kt
//
// DITAMBAHKAN: MethodChannel "sos_rescue/bluetooth" supaya Flutter bisa
// memicu dialog sistem native "Izinkan aplikasi menyalakan Bluetooth?".
// Ganti package di baris `package ...` sesuai package project kamu
// (lihat applicationId di build.gradle.kts: com.example.capstone2).

package com.example.capstone2

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "sos_rescue/bluetooth"
    private val REQUEST_ENABLE_BT = 4321

    // Menyimpan callback sementara sampai hasil dialog Bluetooth diketahui
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val adapter = BluetoothAdapter.getDefaultAdapter()
                when (call.method) {
                    "isBluetoothEnabled" -> {
                        result.success(adapter?.isEnabled ?: false)
                    }
                    "requestEnableBluetooth" -> {
                        if (adapter == null) {
                            // Device tidak punya Bluetooth sama sekali
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        if (adapter.isEnabled) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        pendingResult = result
                        val enableBtIntent =
                            Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                        startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_ENABLE_BT) {
            val granted = resultCode == Activity.RESULT_OK
            pendingResult?.success(granted)
            pendingResult = null
        }
    }
}