package com.example.langfood_flutter

import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var sellerPlayer: MediaPlayer? = null
    private var sellerVibrator: Vibrator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "langfood/seller_order_alert",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    try {
                        playSellerAlert()
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("seller_alert", error.message, null)
                    }
                }
                "stop" -> {
                    stopSellerAlert()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onPause() {
        stopSellerAlert()
        super.onPause()
    }

    @Suppress("DEPRECATION")
    private fun playSellerAlert() {
        stopSellerAlert()
        val audio = getSystemService(AudioManager::class.java)
        if (audio.ringerMode == AudioManager.RINGER_MODE_SILENT) return

        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            getSystemService(Vibrator::class.java)
        }
        if (vibrator.hasVibrator()) {
            val pattern = longArrayOf(0, 170, 110, 170, 110, 220)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1), attributes)
            } else {
                vibrator.vibrate(pattern, -1, attributes)
            }
            sellerVibrator = vibrator
        }
        if (audio.ringerMode != AudioManager.RINGER_MODE_NORMAL) return

        val player = MediaPlayer()
        sellerPlayer = player
        try {
            val key = FlutterInjector.instance().flutterLoader()
                .getLookupKeyForAsset("assets/audio/seller_new_order.wav")
            assets.openFd(key).use { asset ->
                player.setDataSource(asset.fileDescriptor, asset.startOffset, asset.length)
            }
            player.setAudioAttributes(attributes)
            player.setOnPreparedListener { if (sellerPlayer === it) it.start() }
            player.setOnCompletionListener { releaseSellerPlayer(it) }
            player.setOnErrorListener { failedPlayer, _, _ ->
                releaseSellerPlayer(failedPlayer)
                true
            }
            player.prepareAsync()
        } catch (error: Exception) {
            releaseSellerPlayer(player)
            throw error
        }
    }

    private fun releaseSellerPlayer(player: MediaPlayer) {
        if (sellerPlayer !== player) return
        sellerPlayer = null
        player.release()
    }

    private fun stopSellerAlert() {
        sellerPlayer?.let(::releaseSellerPlayer)
        sellerVibrator?.cancel()
        sellerVibrator = null
    }
}
