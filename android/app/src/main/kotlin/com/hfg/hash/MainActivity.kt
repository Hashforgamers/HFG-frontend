package com.hfg.hash

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream

class MainActivity : FlutterActivity() {

private val CHANNEL = "secure_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
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
    }

    private fun readPemFile(inputStream: InputStream): String {
        return inputStream.bufferedReader().use { it.readText() }
    }


}