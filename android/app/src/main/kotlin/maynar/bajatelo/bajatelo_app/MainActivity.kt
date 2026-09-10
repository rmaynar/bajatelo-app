package maynar.bajatelo.bajatelo_app

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "maynar.bajatelo/downloader"
    private val PROGRESS_CHANNEL = "maynar.bajatelo/progress"

    private var progressSink: EventChannel.EventSink? = null
    private var currentProcessId: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            YoutubeDL.getInstance().init(application)
            FFmpeg.getInstance().init(application)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PROGRESS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    progressSink = events
                }

                override fun onCancel(arguments: Any?) {
                    progressSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getVideoInfo" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        getVideoInfo(url, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "URL is required", null)
                    }
                }
                "downloadMedia" -> {
                    val url = call.argument<String>("url")
                    val format = call.argument<String>("format")
                    val outputPath = call.argument<String>("outputPath")
                    if (url != null && format != null && outputPath != null) {
                        downloadMedia(url, format, outputPath, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing arguments", null)
                    }
                }
                "cancelDownload" -> {
                    cancelDownload(result)
                }
                "updateEngine" -> {
                    updateEngine(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getVideoInfo(url: String, result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val request = YoutubeDLRequest(url)
                request.addOption("--dump-json")
                request.addOption("--no-download")
                
                val response = YoutubeDL.getInstance().execute(request, null, null)
                val json = JSONObject(response.out)
                
                val info = JSONObject()
                info.put("id", json.optString("id"))
                info.put("title", json.optString("title"))
                info.put("thumbnail", json.optString("thumbnail"))
                info.put("duration", json.optInt("duration"))
                
                withContext(Dispatchers.Main) {
                    result.success(info.toString())
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("ERROR", e.message, null)
                }
            }
        }
    }

    private fun downloadMedia(url: String, format: String, outputPath: String, result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // Clear the temp output directory so we can easily find the downloaded file
                val tempDir = File(outputPath)
                if (!tempDir.exists()) {
                    tempDir.mkdirs()
                } else {
                    tempDir.listFiles()?.forEach { it.delete() }
                }

                val request = YoutubeDLRequest(url)
                
                if (format == "video") {
                    request.addOption("-f", "bestvideo+bestaudio/best")
                    request.addOption("--merge-output-format", "mp4")
                } else if (format == "audio") {
                    request.addOption("-f", "bestaudio/best")
                    request.addOption("-x")
                    request.addOption("--audio-format", "mp3")
                }
                
                request.addOption("-o", "${tempDir.absolutePath}/%(title)s.%(ext)s")
                
                currentProcessId = "process_${System.currentTimeMillis()}"
                
                YoutubeDL.getInstance().execute(request, currentProcessId) { progress: Float, _: Long, _: String ->
                    CoroutineScope(Dispatchers.Main).launch {
                        progressSink?.success(progress.toDouble() / 100.0)
                    }
                }
                currentProcessId = null
                
                // Find the downloaded file
                val downloadedFile = tempDir.listFiles()?.firstOrNull()
                    ?: throw Exception("Downloaded file not found in temp directory")

                val finalPath = moveToDownloads(downloadedFile, format)
                
                // Call MediaScanner
                MediaScannerConnection.scanFile(
                    applicationContext,
                    arrayOf(finalPath),
                    null,
                    null
                )
                
                val file = File(finalPath)
                val json = JSONObject()
                json.put("filePath", finalPath)
                json.put("fileName", file.name)
                json.put("fileSize", file.length())
                
                withContext(Dispatchers.Main) {
                    result.success(json.toString())
                }
            } catch (e: Exception) {
                currentProcessId = null
                withContext(Dispatchers.Main) {
                    result.error("ERROR", e.message, null)
                }
            }
        }
    }
    
    private fun moveToDownloads(sourceFile: File, format: String): String {
        val mimeType = if (format == "video") "video/mp4" else "audio/mpeg"
        val isVideo = format == "video"
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, sourceFile.name)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                ?: throw Exception("Could not create MediaStore entry")
                
            contentResolver.openOutputStream(uri)?.use { outputStream ->
                FileInputStream(sourceFile).use { inputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
            sourceFile.delete()
            
            // On API 29+, the file is saved to /storage/emulated/0/Download/filename
            val finalFile = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), sourceFile.name)
            return finalFile.absolutePath
        } else {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }
            
            var destFile = File(downloadsDir, sourceFile.name)
            var counter = 1
            val nameWithoutExt = sourceFile.nameWithoutExtension
            val ext = sourceFile.extension
            while (destFile.exists()) {
                destFile = File(downloadsDir, "${nameWithoutExt}_$counter.$ext")
                counter++
            }
            
            sourceFile.copyTo(destFile, overwrite = true)
            sourceFile.delete()
            
            return destFile.absolutePath
        }
    }

    private fun cancelDownload(result: MethodChannel.Result) {
        val processId = currentProcessId
        if (processId != null) {
            try {
                YoutubeDL.getInstance().destroyProcessById(processId)
                result.success(null)
            } catch (e: Exception) {
                result.error("ERROR", e.message, null)
            }
        } else {
            result.success(null)
        }
    }

    private fun updateEngine(result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                YoutubeDL.getInstance().updateYoutubeDL(application)
                withContext(Dispatchers.Main) {
                    result.success(null)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("ERROR", e.message, null)
                }
            }
        }
    }
}
