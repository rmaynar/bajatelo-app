# yt-dlp Architecture and Implementation Details

This document tracks the architectural decisions, historical fixes, and native Android quirks encountered while implementing video and audio downloading via `yt-dlp` and `ffmpeg` in this Flutter application.

**⚠️ AGENT RULE: Always read this file FIRST when investigating any downloading, yt-dlp, or ffmpeg-related bugs.**

## 1. Architecture

### Dart / UI Layer
* **State Management**: Uses Riverpod (`download_notifier.dart`, `download_state.dart`). The state tracks raw terminal errors, progress, and whether the engine needs an update.
* **Error Handling**: Raw terminal errors from `yt-dlp` are parsed by `YtdlpErrorParser` (`lib/core/utils/ytdlp_error_parser.dart`). It categorizes known errors (e.g., HTTP 400, DRM, Geo-restrictions) and flags if a `yt-dlp` engine update is recommended.
* **UI**: The user is presented with actionable error banners (e.g., an "Update Engine" button) and an expandable toggle to see raw `stderr` output.

### Native Android Layer (`MainActivity.kt`)
* **Initialization**: The `YoutubeDL` and `FFmpeg` libraries are initialized asynchronously via Kotlin Coroutines (`Dispatchers.IO`) in `onCreate` to prevent Application Not Responding (ANR) crashes.
* **Auto-updater**: On startup, the app attempts a best-effort, non-blocking update of the `yt-dlp` binary (`YoutubeDL.getInstance().updateYoutubeDL(application)`).
* **Platform Channels**: `AndroidDownloaderService` communicates with `MainActivity.kt` via MethodChannels (`getVideoInfo`, `downloadMedia`, `updateEngine`).

---

## 2. Historical Fixes & Known Quirks

### 2.1. Python Version Compatibility (ImportError)
* **Problem**: Official `yt-dlp` dropped support for Python 3.8. The `com.github.yausername.youtubedl-android:library:0.14.+` dependency bundled Python 3.8, leading to `ImportError: Only Python versions 3.10 and above are supported`.
* **Fix**: Migrated to the community-maintained `io.github.junkfood02.youtubedl-android` fork (`0.18.1`), which bundles Python 3.10.

### 2.2. Native Library Stripping (`llvm-strip` corruption)
* **Problem**: The `youtubedl-android` library distributes Python and FFmpeg inside disguised `.zip.so` files. Android's Gradle plugin attempts to strip debugging symbols from `.so` files using `llvm-strip`, which corrupts these zip payloads.
* **Fix**: Added `useLegacyPackaging = true` and `keepDebugSymbols.add("**/*.zip.so")` to `android/app/build.gradle.kts`.

### 2.3. Audio Extraction & FFprobe Path Resolution
* **Problem**: When downloading audio, `yt-dlp` requires BOTH `ffmpeg` and `ffprobe`. Android extracts native executables with a `lib*.so` prefix (i.e., `libffmpeg.so` and `libffprobe.so`). While passing `--ffmpeg-location libffmpeg.so` works for video (which only needs `ffmpeg`), it fails for audio because `yt-dlp` strictly searches the same directory for a file named exactly `ffprobe` (and executes `os.access(..., os.X_OK)`).
* **Fix**: In `MainActivity.kt`, we programmatically create hardlinks (falling back to symlinks) in the app's `noBackupFilesDir` mapping `libffmpeg.so -> ffmpeg` and `libffprobe.so -> ffprobe`. We then use Java reflection to override `YoutubeDL`'s private static `ffmpegPath` variable to point to our linked `ffmpeg` file. 

### 2.4. Broken Symlinks on App Update (`EEXIST` crash)
* **Problem**: When the app is reinstalled or updated via Android Studio, Android assigns a new randomized directory for `nativeLibraryDir` (e.g., `/data/app/~~<random>/...`). The old symlinks in `noBackupFilesDir` are preserved but become broken. Calling `File.exists()` on a broken symlink returns `false`, causing the deletion step to be skipped. `Os.symlink` then crashes with `EEXIST` (File already exists), silently breaking engine initialization.
* **Fix**: Unconditionally call `.delete()` on the link files before attempting to create new links in `MainActivity.kt`.

### 2.5. Log Noise
* **Problem**: `yt-dlp` emits numerous warnings during metadata extraction, polluting logcat and error parsing.
* **Fix**: Passed `--no-warnings` in the `YoutubeDLRequest` configuration.
