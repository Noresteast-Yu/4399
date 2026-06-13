package com.example.smart_travel_app

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
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
    private val speechPermissionRequestCode = 7012
    private val speechActivityRequestCode = 7013
    private var speechRecognizer: SpeechRecognizer? = null
    private var speechChannel: MethodChannel? = null
    private var pendingSpeechLocale: String? = null

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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED
        ) {
            pendingSpeechLocale = localeTag
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), speechPermissionRequestCode)
            return true
        }

        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            return startSpeechActivity(localeTag)
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
                    val handledByActivity = when (error) {
                        SpeechRecognizer.ERROR_CLIENT,
                        SpeechRecognizer.ERROR_RECOGNIZER_BUSY,
                        SpeechRecognizer.ERROR_SERVER,
                        SpeechRecognizer.ERROR_SERVER_DISCONNECTED -> startSpeechActivity(localeTag)
                        else -> false
                    }
                    if (!handledByActivity) {
                        speechChannel?.invokeMethod("onSpeechError", mapOf("code" to error))
                    }
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

    private fun startSpeechActivity(localeTag: String): Boolean {
        return try {
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(
                    RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                    RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
                )
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.forLanguageTag(localeTag).toLanguageTag())
                putExtra(RecognizerIntent.EXTRA_PROMPT, "请说出终点站")
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            }
            startActivityForResult(intent, speechActivityRequestCode)
            true
        } catch (error: ActivityNotFoundException) {
            speechChannel?.invokeMethod("onSpeechError", mapOf("message" to "speech unavailable"))
            false
        }
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

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != speechPermissionRequestCode) return

        val locale = pendingSpeechLocale
        pendingSpeechLocale = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED && locale != null) {
            startSpeech(locale)
        } else {
            speechChannel?.invokeMethod(
                "onSpeechError",
                mapOf("message" to "microphone permission denied")
            )
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != speechActivityRequestCode) return

        if (resultCode == Activity.RESULT_OK) {
            val text = data
                ?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                ?.firstOrNull()
                ?.trim()
                .orEmpty()
            if (text.isNotEmpty()) {
                speechChannel?.invokeMethod(
                    "onSpeechResult",
                    mapOf("text" to text, "isFinal" to true)
                )
                return
            }
        }
        speechChannel?.invokeMethod("onSpeechDone", null)
    }
}
