package com.hfg.hash

import android.os.Bundle
import com.google.android.gms.ads.identifier.AdvertisingIdClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream

class MainActivity : FlutterActivity() {

    private val secureChannel = "secure_channel"
    private val deviceIdentifierChannel = "device_identifier_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, secureChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPrivateKey" -> {
                        val pem = readPemFile(resources.openRawResource(R.raw.flutter_private))
                        result.success(pem)
                    }
                    "getPublicKey" -> {
                        val pem = readPemFile(resources.openRawResource(R.raw.public_key))
                        result.success(pem)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, deviceIdentifierChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAdvertisingInfo" -> getAdvertisingInfo(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun readPemFile(inputStream: InputStream): String {
        return inputStream.bufferedReader().use { it.readText() }
    }

    private fun getAdvertisingInfo(result: MethodChannel.Result) {
        Thread {
            try {
                val info = AdvertisingIdClient.getAdvertisingIdInfo(applicationContext)
                val payload = hashMapOf<String, Any?>(
                    "gaid" to (info?.id ?: ""),
                    "isLimitAdTrackingEnabled" to (info?.isLimitAdTrackingEnabled ?: false),
                )
                runOnUiThread {
                    result.success(payload)
                }
            } catch (exception: Exception) {
                runOnUiThread {
                    result.error("AD_ID_ERROR", exception.message, null)
                }
            }
        }.start()
    }

}
