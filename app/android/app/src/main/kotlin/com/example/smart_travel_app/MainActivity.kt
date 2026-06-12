package com.example.smart_travel_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val speechChannelName = "smart_travel_app/speech"
    private var speechRecognizer: SpeechRecognizer? = null
    private var speechChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        speechChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, speechChannelName)
        speechChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startSpeech" -> {
                    val locale = call.argument<String>("locale") ?: "zh-CN"
                    result.success(startSpeech(locale))
                }
                "stopSpeech" -> {
                    speechRecognizer?.stopListening()
                    speechChannel?.invokeMethod("onSpeechDone", null)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startSpeech(localeTag: String): Boolean {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            speechChannel?.invokeMethod("onSpeechError", mapOf("message" to "speech unavailable"))
            return false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 7012)
            return false
        }

        speechRecognizer?.destroy()
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).also { recognizer ->
            recognizer.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) = Unit
                override fun onBeginningOfSpeech() = Unit
                override fun onRmsChanged(rmsdB: Float) = Unit
                override fun onBufferReceived(buffer: ByteArray?) = Unit
                override fun onEndOfSpeech() {
                    speechChannel?.invokeMethod("onSpeechDone", null)
                }

                override fun onError(error: Int) {
                    speechChannel?.invokeMethod("onSpeechError", mapOf("code" to error))
                }

                override fun onResults(results: Bundle?) {
                    sendSpeechResult(results, true)
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    sendSpeechResult(partialResults, false)
                }

                override fun onEvent(eventType: Int, params: Bundle?) = Unit
            })
        }

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.forLanguageTag(localeTag).toLanguageTag())
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }
        speechRecognizer?.startListening(intent)
        return true
    }

    private fun sendSpeechResult(bundle: Bundle?, isFinal: Boolean) {
        val text = bundle
            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            ?.firstOrNull()
            ?.trim()
            .orEmpty()
        if (text.isNotEmpty()) {
            speechChannel?.invokeMethod(
                "onSpeechResult",
                mapOf("text" to text, "isFinal" to isFinal)
            )
        }
    }

    override fun onDestroy() {
        speechRecognizer?.destroy()
        speechRecognizer = null
        super.onDestroy()
    }
}
