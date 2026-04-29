package it.dany.memolink

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.memolink.sharing/channel"
    private var pendingSharedUrl: String? = null
    // Mantenuta come instance variable per evitare garbage collection
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSharedUrl" -> {
                        val url = pendingSharedUrl
                        pendingSharedUrl = null
                        result.success(url)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Se l'app è stata aperta da un intent SEND, estrai l'URL subito
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Aggiorna l'intent corrente e gestiscilo
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action == Intent.ACTION_SEND) {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (!sharedText.isNullOrEmpty()) {
                pendingSharedUrl = sharedText
            }
        }
    }
}
