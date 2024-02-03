package com.example.tkfm_recruiter

import io.flutter.embedding.android.FlutterActivity

import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.content.Context
import android.content.Intent

import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager

import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.media.ImageReader
import android.util.Base64
import java.io.ByteArrayOutputStream

import android.app.NotificationManager
import androidx.core.app.NotificationCompat
import android.app.NotificationChannel
import android.app.Service
import android.os.IBinder
import android.util.DisplayMetrics
import android.hardware.display.VirtualDisplay

const val SCREEN_CAPTURE_CHANNEL_ID = "Screen Capture ID"
const val SCREEN_CAPTURE_CHANNEL_NAME = "Screen Capture"

class MainActivity: FlutterActivity() {
    private val CHANNEL = "channel_screenshot"
    private val SCREENSHOT_INTENT_CODE = 999

    private lateinit var mediaProjectionManager: MediaProjectionManager
    private var mediaProjection: MediaProjection? = null
    private var channelResult: MethodChannel.Result? = null
    private lateinit var imageReader: ImageReader
    private var screenWidth: Int = -1
    private var screenHeight: Int = -1
    private var virtualDisplay: VirtualDisplay? = null
    private lateinit var displayMetrics: DisplayMetrics

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createScreenCaptureNotificationChannel()

        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        displayMetrics = context.resources.displayMetrics
        screenWidth = resources.displayMetrics.widthPixels
        screenHeight = resources.displayMetrics.heightPixels
        imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 2)
        imageReader.setOnImageAvailableListener({ reader ->
            val image = reader.acquireLatestImage()
            val buffer = image.planes[0].buffer
            val pixelStride = image.planes[0].pixelStride
            val rowStride = image.planes[0].rowStride
            val rowPadding = rowStride - pixelStride * screenWidth
            
            val bitmap = Bitmap.createBitmap(screenWidth + rowPadding / pixelStride, screenHeight, Bitmap.Config.ARGB_8888)
            bitmap.copyPixelsFromBuffer(buffer)
            
            image.close()
            channelResult?.success(bitmapToBase64(bitmap))
            channelResult = null
            virtualDisplay?.release()
            virtualDisplay = null
        }, null)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getScreenshot") {
                channelResult = result
                getScreenshot()
            }
            else {
                result.notImplemented()
            }
        }
    }

    private fun getScreenshot() {
        startForegroundService(Intent(this, CaptureService::class.java))
        if (mediaProjection == null) {
            startActivityForResult(mediaProjectionManager?.createScreenCaptureIntent(), SCREENSHOT_INTENT_CODE)
        }else{
            setupVirtualDisplay()
        }
    }

    private fun bitmapToBase64(bitmap: Bitmap): String {
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
        val imageBytes = outputStream.toByteArray()
        return Base64.encodeToString(imageBytes, Base64.DEFAULT)
    }

    private fun setupVirtualDisplay() {
        virtualDisplay = mediaProjection?.createVirtualDisplay(
                                "Screenshot",
                                screenWidth,
                                screenHeight,
                                displayMetrics.densityDpi,
                                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                                imageReader.surface,
                                null,
                                null
                            )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == SCREENSHOT_INTENT_CODE && resultCode == RESULT_OK) {
            mediaProjection = mediaProjectionManager?.getMediaProjection(resultCode, data!!)
            setupVirtualDisplay()
        }
    }

    private fun createScreenCaptureNotificationChannel() {
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        // Create the channel for the notification
        val screenCaptureChannel = NotificationChannel(SCREEN_CAPTURE_CHANNEL_ID, SCREEN_CAPTURE_CHANNEL_NAME, NotificationManager.IMPORTANCE_LOW)
        // Set the Notification Channel for the Notification Manager.
        notificationManager.createNotificationChannel(screenCaptureChannel)
    }
}


class CaptureService : Service() {
    override fun onCreate() {
        super.onCreate()
        startForeground(1, NotificationCompat.Builder(this, SCREEN_CAPTURE_CHANNEL_ID).build())
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}