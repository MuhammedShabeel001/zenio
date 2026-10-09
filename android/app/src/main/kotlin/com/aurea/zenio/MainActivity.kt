package com.auren.zenio

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PersistableBundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun getRenderMode(): RenderMode = RenderMode.texture

    private val handler = Handler(Looper.getMainLooper())
    private var clearClipboardPending = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecureScreen" -> {
                        setSecureScreen(call.argument<Boolean>("enabled") == true)
                        result.success(null)
                    }
                    "copySensitive" -> {
                        copySensitive(
                            call.argument<String>("text") ?: "",
                            (call.argument<Int>("clearAfterSeconds") ?: 60).toLong(),
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Hides the window from screenshots, screen recording and Recents. */
    private fun setSecureScreen(enabled: Boolean) {
        if (enabled) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    /**
     * Copies [text] marked as sensitive (Android 13+ hides the preview) and
     * clears it after [clearAfterSeconds], but only if Zenio's clip is still
     * the current one. Clipboard access needs focus, so a clear that comes due
     * while the app is in the background waits until it regains focus.
     */
    private fun copySensitive(text: String, clearAfterSeconds: Long) {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText(CLIP_LABEL, text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            // The constant is API 33, but keyboards on older versions also
            // honour the same key (per the Android clipboard guide).
            clip.description.extras = PersistableBundle().apply {
                putBoolean(SENSITIVE_EXTRA, true)
            }
        }
        clipboard.setPrimaryClip(clip)

        clearClipboardPending = false
        handler.removeCallbacksAndMessages(CLEAR_TOKEN)
        handler.postAtTime(
            {
                if (hasWindowFocus()) clearZenioClip() else clearClipboardPending = true
            },
            CLEAR_TOKEN,
            android.os.SystemClock.uptimeMillis() + clearAfterSeconds * 1000,
        )
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && clearClipboardPending) clearZenioClip()
    }

    private fun clearZenioClip() {
        clearClipboardPending = false
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        // Only the description is inspected, never the copied content.
        if (clipboard.primaryClipDescription?.label != CLIP_LABEL) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            clipboard.clearPrimaryClip()
        } else {
            clipboard.setPrimaryClip(ClipData.newPlainText("", ""))
        }
    }

    private companion object {
        const val CHANNEL = "com.auren.zenio/security"
        const val CLIP_LABEL = "Zenio sensitive"
        const val SENSITIVE_EXTRA = "android.content.extra.IS_SENSITIVE"
        val CLEAR_TOKEN = Any()
    }
}
