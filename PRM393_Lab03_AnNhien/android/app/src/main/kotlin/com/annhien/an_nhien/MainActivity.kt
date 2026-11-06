package com.annhien.an_nhien

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.speech.RecognizerIntent
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    private var recognizeResult: MethodChannel.Result? = null
    private var documentResult: MethodChannel.Result? = null
    private var documentBytes: ByteArray? = null
    private var speechResult: MethodChannel.Result? = null
    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var speechGeneration = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "an_nhien/device_access")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "recognize" -> {
                        if (recognizeResult != null) { result.error("busy", "Bác đang nói một việc khác.", null); return@setMethodCallHandler }
                        recognizeResult = result
                        try {
                            startActivityForResult(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE, "vi-VN")
                                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                                putExtra(RecognizerIntent.EXTRA_PROMPT, "Bác nói tên việc muốn làm")
                            }, 701)
                        } catch (_: ActivityNotFoundException) {
                            recognizeResult = null
                            result.error("unavailable", "Máy chưa có nhận giọng nói. Bác có thể gõ tên việc hoặc cài dịch vụ giọng nói tiếng Việt.", null)
                        }
                    }
                    "speak" -> speak(call.arguments as? String ?: "", result)
                    "stopSpeaking" -> { stopSpeaking(); result.success(null) }
                    "notificationSettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                            result.success(null)
                        } catch (_: Exception) { result.error("settings", "Chưa mở được cài đặt thông báo.", null) }
                    }
                    "savePdf" -> {
                        if (documentResult != null) { result.error("busy", "Bác lưu xong tệp đang mở trước nhé.", null); return@setMethodCallHandler }
                        documentBytes = call.argument<ByteArray>("bytes")
                        if (documentBytes == null) { result.error("empty", "Chưa tạo được tệp lịch.", null); return@setMethodCallHandler }
                        documentResult = result
                        try {
                            startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "application/pdf"
                                putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "lich-tuan.pdf")
                            }, 702)
                        } catch (_: Exception) {
                            documentResult = null; documentBytes = null
                            result.error("save", "Máy chưa mở được nơi lưu PDF.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun stopSpeaking() {
        speechGeneration++
        tts?.stop()
        speechResult?.success(null)
        speechResult = null
    }

    private fun speak(text: String, result: MethodChannel.Result) {
        stopSpeaking()
        if (text.isBlank()) { result.success(null); return }
        speechResult = result
        val generation = speechGeneration
        if (ttsReady) { beginSpeech(text, generation); return }
        tts?.shutdown()
        tts = TextToSpeech(applicationContext) { status ->
            runOnUiThread {
                if (generation != speechGeneration) return@runOnUiThread
                ttsReady = status == TextToSpeech.SUCCESS
                if (ttsReady) beginSpeech(text, generation)
                else finishSpeech(generation, "Máy chưa có bộ đọc. Bác kiểm tra dịch vụ chuyển văn bản thành giọng nói nhé.")
            }
        }
    }

    private fun beginSpeech(text: String, generation: Int) {
        val engine = tts ?: return
        val language = engine.setLanguage(Locale.forLanguageTag("vi-VN"))
        if (language == TextToSpeech.LANG_MISSING_DATA || language == TextToSpeech.LANG_NOT_SUPPORTED) {
            finishSpeech(generation, "Máy chưa có giọng đọc tiếng Việt. Bác tải giọng tiếng Việt trong cài đặt chuyển văn bản thành giọng nói nhé.")
            return
        }
        engine.setSpeechRate(0.85f)
        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(id: String?) {}
            override fun onDone(id: String?) { runOnUiThread { finishSpeech(generation, null) } }
            @Deprecated("Android callback")
            override fun onError(id: String?) { runOnUiThread { finishSpeech(generation, "Chưa đọc được. Bác thử lại nhé.") } }
        })
        if (engine.speak(text, TextToSpeech.QUEUE_FLUSH, Bundle(), "an-nhien-$generation") == TextToSpeech.ERROR) {
            finishSpeech(generation, "Chưa đọc được. Bác thử lại nhé.")
        }
    }

    private fun finishSpeech(generation: Int, error: String?) {
        if (generation != speechGeneration) return
        val result = speechResult; speechResult = null
        if (error == null) result?.success(null) else result?.error("speech", error, null)
    }

    @Deprecated("Activity result compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 701) {
            val result = recognizeResult; recognizeResult = null
            val text = if (resultCode == Activity.RESULT_OK)
                data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull() else null
            result?.success(text)
        } else if (requestCode == 702) {
            val result = documentResult; documentResult = null
            val bytes = documentBytes; documentBytes = null
            val uri = data?.data
            if (resultCode != Activity.RESULT_OK || uri == null) { result?.success(null); return }
            try {
                val output = contentResolver.openOutputStream(uri) ?: throw IllegalStateException()
                output.use { it.write(bytes ?: throw IllegalStateException()) }
                result?.success(uri.toString())
            } catch (_: Exception) { result?.error("write", "Chưa lưu được PDF. Bác chọn nơi lưu khác rồi thử lại nhé.", null) }
        }
    }

    override fun onStop() {
        stopSpeaking()
        super.onStop()
    }
    override fun onDestroy() {
        stopSpeaking(); tts?.shutdown(); tts = null
        recognizeResult?.success(null); recognizeResult = null
        documentResult?.success(null); documentResult = null; documentBytes = null
        super.onDestroy()
    }
}
