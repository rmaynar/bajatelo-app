package maynar.bajatelo.bajatelo

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

                    val ffmpegField = YoutubeDL::class.java.getDeclaredField("ffmpegPath")
                    ffmpegField.isAccessible = true
                    ffmpegField.set(YoutubeDL.getInstance(), ffmpegSymlink)
                } catch (symlinkError: Exception) {
                    initError = "Symlink failed: " + symlinkError.message
                    symlinkError.printStackTrace()
                    throw symlinkError
                }

                // FIX: Inject a Python wrapper as the yt-dlp entrypoint.
                //
                // Root cause (diagnosed 2026-09-11): youtubedl-android sets LD_LIBRARY_PATH for
                // the Python subprocess to include nativeLibraryDir, but NOT the ffmpeg codec
                // packages dir (noBackupFilesDir/youtubedl-android/packages/ffmpeg/usr/lib/).
                // When yt-dlp then spawns `libffprobe.so -bsfs` to validate the binary, the
                // dynamic linker cannot find libavdevice.so.61 and crashes with
                // "CANNOT LINK EXECUTABLE". yt-dlp interprets this OSError as "ffprobe not found".
                //
                // Fix: a wrapper script that prepends the codec lib dir to os.environ['LD_LIBRARY_PATH']
                // before yt-dlp runs. Python's subprocess.Popen inherits os.environ by default,
                // so all subsequent ffprobe/ffmpeg sub-subprocesses see the correct path.
                try {
                    installYtdlpWrapper()
                } catch (wrapperError: Exception) {
                    // Non-fatal: fall back to unpatched yt-dlp (audio will still fail, but app won't crash)
                    android.util.Log.e("BAJATELO", "Failed to install yt-dlp wrapper: ${wrapperError.message}", wrapperError)
                }

                isInitialized = true
                // Auto-update yt-dlp to latest version (best-effort, non-blocking)
                try {
                    YoutubeDL.getInstance().updateYoutubeDL(application)
                    // Re-install wrapper after update since updateYoutubeDL may reset ytdlpPath
                    installYtdlpWrapper()
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

    // Stores the real yt-dlp zip path so installYtdlpWrapper() can safely be called
    // multiple times (e.g. after updateYoutubeDL()) without creating a self-reference loop.
    private var originalYtdlpPath: File? = null

    private fun installYtdlpWrapper() {
        val noBackupDir = application.noBackupFilesDir
        val ytdlpPathField = YoutubeDL::class.java.getDeclaredField("ytdlpPath")
        ytdlpPathField.isAccessible = true

        // On first call, capture the real yt-dlp zip path before overriding it.
        // On subsequent calls (after updateYoutubeDL), ytdlpPath may already point to our
        // wrapper — guard against that to prevent infinite recursion in the script.
        val currentPath = ytdlpPathField.get(YoutubeDL.getInstance()) as File
        val wrapperScript = File(noBackupDir, "yt_dlp_wrapper.py")

        if (currentPath.absolutePath != wrapperScript.absolutePath) {
            // First call: save the real yt-dlp zip path
            originalYtdlpPath = currentPath
        }

        val realYtdlpPath = originalYtdlpPath
            ?: throw IllegalStateException("originalYtdlpPath not set")

        // The ffmpeg codec shared libraries are extracted here by youtubedl-android
        val ffmpegLibDir = File(noBackupDir, "youtubedl-android/packages/ffmpeg/usr/lib")

        // Write the wrapper script (regenerate each time in case paths changed)
        val nativeLibDir = application.applicationInfo.nativeLibraryDir

        wrapperScript.writeText("""
import sys
import os
import runpy

_ffmpeg_lib_dir = "${ffmpegLibDir.absolutePath}"
_native_lib_dir = "${nativeLibDir}"

if os.path.isdir(_ffmpeg_lib_dir):
    _existing = os.environ.get('LD_LIBRARY_PATH', '')
    # youtubedl-android sets LD_LIBRARY_PATH to only the extracted packages, but omits
    # the app's nativeLibraryDir (causing missing libc++_shared.so).
    # We must explicitly construct a path that contains BOTH the native lib dir AND all the packages.
    _python_lib_dir = "${File(noBackupDir, "youtubedl-android/packages/python/usr/lib").absolutePath}"
    _aria2c_lib_dir = "${File(noBackupDir, "youtubedl-android/packages/aria2c/usr/lib").absolutePath}"
    
    _new_ld = _ffmpeg_lib_dir + ":" + _python_lib_dir + ":" + _aria2c_lib_dir + ":" + _native_lib_dir
    os.environ['LD_LIBRARY_PATH'] = _new_ld + (':' + _existing if _existing else '')

_ytdlp_zip = "${realYtdlpPath.absolutePath}"
sys.argv[0] = _ytdlp_zip
runpy.run_path(_ytdlp_zip, run_name='__main__')
""".trimIndent())

        // Point YoutubeDL at our wrapper
        ytdlpPathField.set(YoutubeDL.getInstance(), wrapperScript)
        android.util.Log.d("BAJATELO", "yt-dlp wrapper installed → real yt-dlp: ${realYtdlpPath.absolutePath}")
        android.util.Log.d("BAJATELO", "ffmpeg lib dir: ${ffmpegLibDir.absolutePath} exists=${ffmpegLibDir.exists()}")
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
