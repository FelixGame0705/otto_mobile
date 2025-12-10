package com.otto.ottobit

import android.content.Context
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import java.io.OutputStream

class MainActivity: FlutterActivity() {
    private val channelName = "com.otto.ottobit/usb"
    private var pendingBytes: ByteArray? = null
    private var pendingResult: MethodChannel.Result? = null
    private val REQUEST_CREATE_DOCUMENT = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "listUsbDevices" -> {
                    try {
                        val devices = listUsbDevices()
                        result.success(devices)
                    } catch (e: Exception) {
                        result.error("USB_ERROR", e.message, null)
                    }
                }
                "openAllFilesAccessSettings" -> {
                    try {
                        openAllFilesAccessSettings()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("PERMISSION_ERROR", e.message, null)
                    }
                }
                "createDocumentAndWrite" -> {
                    try {
                        val fileName = call.argument<String>("fileName") ?: "firmware.hex"
                        val data = call.argument<ByteArray>("bytes")
                        if (data == null) {
                            result.error("ARG_ERROR", "Missing bytes", null)
                        } else {
                            pendingBytes = data
                            pendingResult = result
                            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "application/octet-stream"
                                putExtra(Intent.EXTRA_TITLE, fileName)
                            }
                            startActivityForResult(intent, REQUEST_CREATE_DOCUMENT)
                        }
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CREATE_DOCUMENT) {
            val result = pendingResult
            val bytes = pendingBytes
            pendingResult = null
            pendingBytes = null
            if (result == null || bytes == null) return

            if (resultCode == Activity.RESULT_OK) {
                val uri: Uri? = data?.data
                if (uri != null) {
                    try {
                        val out: OutputStream? = contentResolver.openOutputStream(uri, "w")
                        out?.use { it.write(bytes) }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WRITE_ERROR", e.message, null)
                    }
                } else {
                    result.error("NO_URI", "No URI returned", null)
                }
            } else {
                result.error("CANCELLED", "User cancelled", null)
            }
        }
    }

    private fun listUsbDevices(): List<Map<String, Any>> {
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        val deviceList: HashMap<String, UsbDevice> = usbManager.deviceList
        val out = mutableListOf<Map<String, Any>>()
        for ((_, device) in deviceList) {
            val item = hashMapOf<String, Any>(
                "deviceName" to (device.productName ?: device.deviceName ?: "USB Device"),
                "manufacturerName" to (device.manufacturerName ?: "Unknown"),
                "productName" to (device.productName ?: "Unknown"),
                "vendorId" to device.vendorId,
                "productId" to device.productId,
                "deviceId" to device.deviceId,
                "deviceClass" to device.deviceClass,
                "deviceSubclass" to device.deviceSubclass,
                "deviceProtocol" to device.deviceProtocol
            )
            out.add(item)
        }
        return out
    }

    private fun openAllFilesAccessSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                intent.addCategory("android.intent.category.DEFAULT")
                intent.data = Uri.parse(String.format("package:%s", applicationContext.packageName))
                startActivity(intent)
            } catch (e: Exception) {
                val intent = Intent()
                intent.action = Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION
                startActivity(intent)
            }
        } else {
            val intent = Intent()
            intent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
            intent.data = Uri.fromParts("package", packageName, null)
            startActivity(intent)
        }
    }
}
