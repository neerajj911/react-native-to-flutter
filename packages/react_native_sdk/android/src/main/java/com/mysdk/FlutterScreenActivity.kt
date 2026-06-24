package com.mysdk

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class FlutterScreenActivity : FlutterActivity() {

    private val channelName = "sdk_channel"

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return FlutterEngineCache.getInstance().get(MySDKModule.ENGINE_ID)
            ?: super.provideFlutterEngine(context)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)

        val payload = HashMap<String, String>()
        intent.extras?.keySet()?.forEach { k ->
            intent.getStringExtra(k)?.let { payload[k] = it }
        }

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getParams" -> result.success(payload)
                "ready" -> {
                    channel.invokeMethod("setUser", payload)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
