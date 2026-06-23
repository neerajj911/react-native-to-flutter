package com.mysdk

import android.content.Intent
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class MySDKModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName() = "MySDKModule"

    @ReactMethod
    fun open(data: ReadableMap) {
        ensureEngine()
        val intent = Intent(reactContext, FlutterScreenActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            val keys = data.keySetIterator()
            while (keys.hasNextKey()) {
                val k = keys.nextKey()
                putExtra(k, data.getString(k))
            }
        }
        reactContext.startActivity(intent)
    }

    private fun ensureEngine() {
        if (FlutterEngineCache.getInstance().get(ENGINE_ID) != null) return
        val engine = FlutterEngine(reactContext.applicationContext)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
    }

    companion object {
        const val ENGINE_ID = "sdk_engine"
    }
}
