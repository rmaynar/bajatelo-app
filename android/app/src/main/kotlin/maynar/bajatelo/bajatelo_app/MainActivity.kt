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
    private var isInitialized = false
    private var initError: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        CoroutineScope(Dispatchers.IO).launch {
            try {
                YoutubeDL.getInstance().init(application)
                FFmpeg.getInstance().init(application)
                
                // yt-dlp needs BOTH ffmpeg and ffprobe to merge/extract audio, but youtubedl-android
                // only passes libffmpeg.so. We create symlinks with standard names and reflectively update it.
                try {
                    val symlinkDir = File(application.noBackupFilesDir, "ffmpeg_symlinks")
                    if (!symlinkDir.exists()) symlinkDir.mkdirs()
                    
                    val ffmpegSymlink = File(symlinkDir, "ffmpeg")
                    val ffprobeSymlink = File(symlinkDir, "ffprobe")
                    
                    val nativeLibDir = application.applicationInfo.nativeLibraryDir
                    val libffmpeg = File(nativeLibDir, "libffmpeg.so")
                    val libffprobe = File(nativeLibDir, "libffprobe.so")
                    
                    // Always try to delete first to handle broken symlinks from previous app installs
                    ffmpegSymlink.delete()
                    ffprobeSymlink.delete()
                    
                    try {
                        android.system.Os.link(libffmpeg.absolutePath, ffmpegSymlink.absolutePath)
                        android.system.Os.link(libffprobe.absolutePath, ffprobeSymlink.absolutePath)
                    } catch (linkError: Exception) {
                        // Fallback to symlink if hardlink fails (e.g. cross-device)
                        android.system.Os.symlink(libffmpeg.absolutePath, ffmpegSymlink.absolutePath)
                        android.system.Os.symlink(libffprobe.absolutePath, ffprobeSymlink.absolutePath)
                    }
                    
                    val field = YoutubeDL::class.java.getDeclaredField("ffmpegPath")
                    field.isAccessible = true
                    field.set(YoutubeDL.getInstance(), ffmpegSymlink)
                } catch (symlinkError: Exception) {
                    initError = "Symlink failed: " + symlinkError.message
                    symlinkError.printStackTrace()
                    throw symlinkError
                }

                isInitialized = true

                // === DIAGNOSTIC BLOCK (D2, D3, D4) — remove after investigation ===
                runDiagnostics()
                // === END DIAGNOSTIC BLOCK ===

                // Auto-update yt-dlp to latest version (best-effort, non-blocking)
                try {
                    YoutubeDL.getInstance().updateYoutubeDL(application)
                } catch (updateError: Exception) {
                    // Update failed (offline, etc.) — not fatal, continue with bundled version
                    updateError.printStackTrace()
                }
            } catch (e: Exception) {
                if (initError == null) {
                    initError = e.message ?: "Unknown initialization error"
                }
                e.printStackTrace()
            }
        }
    }

    /**
     * DIAGNOSTIC: Tasks D2, D3, D4 from yt_dlp_audio_fix_plan.md
     * Logs to logcat tagged DIAG_D2, DIAG_D3, DIAG_D4.
     * Filter with: adb logcat -s DIAG_D2 DIAG_D3 DIAG_D4
     */
    private fun runDiagnostics() {
        val TAG_D2 = "DIAG_D2"
        val TAG_D3 = "DIAG_D3"
        val TAG_D4 = "DIAG_D4"

        // ── D2: Map internal paths and LD_LIBRARY_PATH ──────────────────────────
        try {
            android.util.Log.d(TAG_D2, "=== D2: Internal paths and environment ===")
            android.util.Log.d(TAG_D2, "nativeLibraryDir: ${application.applicationInfo.nativeLibraryDir}")
            android.util.Log.d(TAG_D2, "noBackupFilesDir: ${application.noBackupFilesDir}")
            android.util.Log.d(TAG_D2, "LD_LIBRARY_PATH: ${System.getenv("LD_LIBRARY_PATH")}")
            android.util.Log.d(TAG_D2, "PATH: ${System.getenv("PATH")}")
            android.util.Log.d(TAG_D2, "PYTHONHOME: ${System.getenv("PYTHONHOME")}")

            // Reflect all File fields from YoutubeDL instance
            val ytdl = YoutubeDL.getInstance()
            for (f in ytdl.javaClass.declaredFields) {
                f.isAccessible = true
                val v = f.get(ytdl)
                if (v is File || v == null) {
                    android.util.Log.d(TAG_D2, "YoutubeDL.${f.name} = $v")
                }
            }

            // Scan noBackupFilesDir for extracted ffmpeg libraries
            android.util.Log.d(TAG_D2, "--- noBackupFilesDir tree ---")
            application.noBackupFilesDir.walkTopDown().forEach { f ->
                if (f.name.contains("ffmpeg") || f.name.contains("ffprobe") ||
                    f.name.contains("libav") || f.name.contains("libsw")) {
                    android.util.Log.d(TAG_D2, "  ${f.absolutePath} (${f.length()} bytes, exec=${f.canExecute()})")
                }
            }
        } catch (e: Exception) {
            android.util.Log.e(TAG_D2, "D2 failed: ${e.message}", e)
        }

        // ── D3: Test direct binary execution ────────────────────────────────────
        try {
            android.util.Log.d(TAG_D3, "=== D3: Direct binary execution tests ===")
            val nativeLibDir = application.applicationInfo.nativeLibraryDir
            val symlinkDir   = File(application.noBackupFilesDir, "ffmpeg_symlinks")
            val currentLd    = System.getenv("LD_LIBRARY_PATH") ?: ""

            data class ExecTest(val label: String, val path: String, val withLd: Boolean)
            val tests = listOf(
                ExecTest("libffprobe.so (nativeLibDir, WITH LD_LIB)", "$nativeLibDir/libffprobe.so", true),
                ExecTest("ffprobe symlink (noBackupFilesDir, WITH LD_LIB)", "${symlinkDir}/ffprobe", true),
                ExecTest("libffprobe.so (nativeLibDir, WITHOUT LD_LIB)", "$nativeLibDir/libffprobe.so", false),
                ExecTest("libffmpeg.so (nativeLibDir, WITH LD_LIB)", "$nativeLibDir/libffmpeg.so", true),
            )

            for (test in tests) {
                try {
                    val pb = ProcessBuilder(listOf(test.path, "-version"))
                    pb.redirectErrorStream(true)
                    if (test.withLd) pb.environment()["LD_LIBRARY_PATH"] = currentLd
                    else pb.environment().remove("LD_LIBRARY_PATH")
                    val proc = pb.start()
                    val output = proc.inputStream.bufferedReader().readText()
                    val exitCode = proc.waitFor()
                    android.util.Log.d(TAG_D3, "[${test.label}] exit=$exitCode output=${output.take(200)}")
                } catch (e: Exception) {
                    android.util.Log.e(TAG_D3, "[${test.label}] EXCEPTION: ${e.javaClass.simpleName}: ${e.message}")
                }
            }
        } catch (e: Exception) {
            android.util.Log.e(TAG_D3, "D3 failed: ${e.message}", e)
        }

        // ── D4: Check yt-dlp Popen / PyInstaller env stripping ──────────────────
        try {
            android.util.Log.d(TAG_D4, "=== D4: yt-dlp Popen and PyInstaller check ===")
            // Find the yt-dlp package on disk
            val ytdlpSearchDirs = listOf(
                application.noBackupFilesDir,
                application.filesDir,
            )
            for (dir in ytdlpSearchDirs) {
                dir.walkTopDown().maxDepth(6).forEach { f ->
                    if (f.name == "_utils.py" || f.name == "__main__.py" || f.name == "YoutubeDL.py") {
                        android.util.Log.d(TAG_D4, "Found: ${f.absolutePath}")
                        // Search for PyInstaller markers and _fix_pyinstaller_issues
                        val content = f.readText()
                        if (content.contains("_fix_pyinstaller") || content.contains("_MEIPASS") ||
                            content.contains("LD_LIBRARY_PATH")) {
                            android.util.Log.d(TAG_D4, "  >>> MATCH in ${f.name}: contains PyInstaller/LD_LIBRARY_PATH references")
                            // Log the relevant lines
                            content.lines().forEachIndexed { i, line ->
                                if (line.contains("_fix_pyinstaller") || line.contains("_MEIPASS") ||
                                    line.contains("LD_LIBRARY_PATH")) {
                                    android.util.Log.d(TAG_D4, "  L${i+1}: $line")
                                }
                            }
                        }
                    }
                }
            }
            android.util.Log.d(TAG_D4, "_MEIPASS env: ${System.getenv("_MEIPASS")}")
            android.util.Log.d(TAG_D4, "D4 done")
        } catch (e: Exception) {
            android.util.Log.e(TAG_D4, "D4 failed: ${e.message}", e)
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

    private suspend fun ensureInitialized() {
        // Wait for async init to complete (max ~10 seconds)
        var retries = 0
        while (!isInitialized && initError == null && retries < 100) {
            kotlinx.coroutines.delay(100)
            retries++
        }
        if (!isInitialized) {
            throw Exception(initError ?: "YoutubeDL engine failed to initialize. Please restart the app.")
        }
    }

    private fun getVideoInfo(url: String, result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                ensureInitialized()
                val request = YoutubeDLRequest(url)
                request.addOption("--dump-json")
                request.addOption("--no-download")
                request.addOption("--no-warnings")
                
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
                ensureInitialized()
                // Clear the temp output directory so we can easily find the downloaded file
                val tempDir = File(outputPath)
                if (!tempDir.exists()) {
                    tempDir.mkdirs()
                } else {
                    tempDir.listFiles()?.forEach { it.delete() }
                }

                val request = YoutubeDLRequest(url)
                
                // DIAGNOSTIC D1: add verbose flag to capture whether ffmpeg is actually invoked
                request.addOption("-v")

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
                
                val response = YoutubeDL.getInstance().execute(request, currentProcessId) { progress: Float, _: Long, _: String ->
                    CoroutineScope(Dispatchers.Main).launch {
                        progressSink?.success(progress.toDouble() / 100.0)
                    }
                }
                currentProcessId = null

                // DIAGNOSTIC D1: log full yt-dlp output to detect ffmpeg usage
                android.util.Log.d("DIAG_D1", "=== D1: yt-dlp output (format=$format) ===")
                response.out.lines().forEach { line ->
                    if (line.contains("[Merger]") || line.contains("[ffmpeg]") ||
                        line.contains("ffprobe") || line.contains("Downloading 1 format") ||
                        line.contains("Merging") || line.contains("Postprocessing")) {
                        android.util.Log.d("DIAG_D1", "KEY: $line")
                    }
                }
                response.err.lines().takeLast(40).forEach { line ->
                    android.util.Log.d("DIAG_D1", "ERR: $line")
                }

                
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
                ensureInitialized()
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
