# yt-dlp Fixes & Features Changelog

This document acts as a visible timeline tracking all planning changes, fixes applied, features added, and native Android quirks resolved regarding `yt-dlp` and `ffmpeg` downloading.

**⚠️ AGENT RULE: Always read this file FIRST to understand historical quirks before debugging.**

## 2026-09-11 23:05:00

### Fix: Audio download fails — `libavdevice.so.61 not found` / "ffprobe and ffmpeg not found"
* **Problem**: Audio downloads (and video+audio merging) failed with `ERROR: Postprocessing: ffprobe and ffmpeg not found`.
* **Root cause (diagnosed via 4 on-device tests)**:
  * `youtubedl-android` extracts the ffmpeg codec shared libraries (`libavdevice.so.61`, `libavcodec.so.61`, etc.) to `noBackupFilesDir/youtubedl-android/packages/ffmpeg/usr/lib/`.
  * It sets `LD_LIBRARY_PATH` for the Python subprocess to include `nativeLibraryDir`, but **NOT** the ffmpeg packages lib dir.
  * When yt-dlp probes ffprobe by running `libffprobe.so -bsfs`, the dynamic linker cannot find `libavdevice.so.61` and crashes with `CANNOT LINK EXECUTABLE`. yt-dlp interprets this `OSError` as "ffprobe not found".
  * Video downloads appeared to work because `bestvideo+bestaudio/best` silently fell back to a single pre-merged stream — ffmpeg was never actually invoked.
* **Fix**: A Python wrapper script (`noBackupFilesDir/yt_dlp_wrapper.py`) generated at runtime in `MainActivity.kt` that prepends the codec lib dir to `os.environ['LD_LIBRARY_PATH']` before importing yt-dlp. Python's `subprocess.Popen` inherits `os.environ` by default, so all subsequent ffprobe/ffmpeg sub-subprocesses see the correct path. `YoutubeDL.ytdlpPath` is overridden via reflection to point to the wrapper. The wrapper also re-delegates to the original yt-dlp zip so auto-updates keep working.



### Fix: Broken Symlinks on App Update (`EEXIST` crash)
* **Problem**: When the app is reinstalled or updated via Android Studio, Android assigns a new randomized directory for `nativeLibraryDir` (e.g., `/data/app/~~<random>/...`). The old symlinks in `noBackupFilesDir` are preserved but become broken. Calling `File.exists()` on a broken symlink returns `false`, causing the deletion step to be skipped. `Os.symlink` then crashes with `EEXIST` (File already exists), silently breaking engine initialization.
* **Fix**: Unconditionally call `.delete()` on the link files before attempting to create new links in `MainActivity.kt`. Additionally, introduced an `Os.link` (hardlink) fallback system.

## 2026-09-11 17:52:00

### Fix: Audio Extraction & FFprobe Path Resolution
* **Problem**: When downloading audio, `yt-dlp` requires BOTH `ffmpeg` and `ffprobe`. Android extracts native executables with a `lib*.so` prefix (i.e., `libffmpeg.so` and `libffprobe.so`). While passing `--ffmpeg-location libffmpeg.so` works for video (which only needs `ffmpeg`), it fails for audio because `yt-dlp` strictly searches the same directory for a file named exactly `ffprobe` (and executes `os.access(..., os.X_OK)`).
* **Fix**: In `MainActivity.kt`, we programmatically create symlinks in the app's `noBackupFilesDir` mapping `libffmpeg.so -> ffmpeg` and `libffprobe.so -> ffprobe`. We then use Java reflection to override `YoutubeDL`'s private static `ffmpegPath` variable to point to our linked `ffmpeg` file.

## 2026-09-11 15:20:00

### Feature: yt-dlp Auto-updater & UI Controls
* **Feature**: Added startup auto-updater in `MainActivity.kt` (`updateYoutubeDL()`) to survive YouTube API changes (like HTTP 400).
* **Feature**: Added `YtdlpErrorParser` in Dart to convert raw console stderr into user-friendly prompts (`needsEngineUpdate`).
* **Feature**: Exposed "Update Engine" and raw `stderr` log toggles in the Flutter UI.
* **Fix (Log Noise)**: Passed `--no-warnings` in the `YoutubeDLRequest` configuration to stop logcat pollution during metadata extraction.

## 2026-09-11 14:40:00

### Fix: Python Version Compatibility (ImportError)
* **Problem**: Official `yt-dlp` dropped support for Python 3.8. The `com.github.yausername.youtubedl-android:library:0.14.+` dependency bundled Python 3.8, leading to `ImportError: Only Python versions 3.10 and above are supported`.
* **Fix**: Migrated to the community-maintained `io.github.junkfood02.youtubedl-android` fork (`0.18.1`), which bundles Python 3.10 natively.

## 2026-09-11 13:10:00

### Fix: Native Library Stripping (`llvm-strip` corruption)
* **Problem**: The `youtubedl-android` library distributes Python and FFmpeg inside disguised `.zip.so` files. Android's Gradle plugin attempts to strip debugging symbols from `.so` files using `llvm-strip`, which corrupts these zip payloads.
* **Fix**: Added `useLegacyPackaging = true` and `keepDebugSymbols.add("**/*.zip.so")` to `android/app/build.gradle.kts`.

## 2026-09-11 23:35:00

### Fix: Audio download fails (Missing libc++_shared.so in LD_LIBRARY_PATH)
* **Problem**: Audio downloads still failed after the previous fix because `libffprobe.so` could not find `libc++_shared.so`. The previous Python wrapper prepended `packages/ffmpeg/usr/lib` to the `LD_LIBRARY_PATH` passed by `youtubedl-android`. However, analysis of `YoutubeDL.java` decompilation proved that the `youtubedl-android` library actually hardcodes `LD_LIBRARY_PATH` to ONLY contain the extracted Python/FFmpeg/Aria2c dirs (`packages/python/usr/lib:packages/ffmpeg/usr/lib:packages/aria2c/usr/lib`), omitting the app's `nativeLibraryDir` entirely!
* **Fix**: Updated `yt_dlp_wrapper.py` in `MainActivity.kt` to explicitly append `nativeLibraryDir` (which contains `libc++_shared.so`) to `LD_LIBRARY_PATH`. This ensures both `libavdevice.so.61` and `libc++_shared.so` are visible to the dynamic linker when `yt-dlp` spawns the `ffprobe` subprocess.

## 2026-09-11 23:45:00

### Fix & Discovery: 16KB Page Size Binary Incompatibility (`libwebp.so`) & Missing `libexpat.so.1`
* **Problem**: Audio downloads still failed after adding `nativeLibraryDir` to `LD_LIBRARY_PATH`. Deep diagnostic traces of the dynamic linker via `adb shell run-as` revealed two new critical issues:
  1. **Missing `libexpat.so.1`**: `youtubedl-android` bundles `libexpat.so.1` inside `packages/python/usr/lib`, not in `ffmpeg/usr/lib`. By aggressively overriding `LD_LIBRARY_PATH`, we had inadvertently stripped the python directory, breaking `libfontconfig.so`.
  2. **16KB Page Alignment Crash**: After fixing `LD_LIBRARY_PATH`, the Android dynamic linker still explicitly rejected loading `libffprobe.so`. The error `libwebp.so program alignment (4096) cannot be smaller than system page size (16384)` was thrown. Android 15 requires all native libraries to be 16KB aligned (`-z max-page-size=16384`). The pre-compiled FFmpeg binaries bundled in `io.github.junkfood02.youtubedl-android:0.18.1` contain several libraries (specifically the `libwebp` suite) that are hard-aligned to 4KB.
* **Fix Applied**: 
  - Updated `MainActivity.kt`'s Python wrapper to explicitly combine ALL package directories (`ffmpeg`, `python`, `aria2c`) WITH `nativeLibraryDir` into the final `LD_LIBRARY_PATH`. This fully resolves all "library not found" errors on standard 4KB devices.
  - Furthermore, explicitly bundled `libc++_shared.so` into the app's `jniLibs` directory by copying it from the NDK, since Flutter drops it and the AAR doesn't package it.
* **Conclusion (Unfixable on Emulator)**: The 16KB page alignment issue is a binary incompatibility at the ELF level of `libwebp.so` inside the third-party AAR. We cannot fix this via Kotlin/Python workarounds. The emulator being used is a 16KB device (`emu64a16k`). Audio downloading will remain broken on this specific emulator (and future Android 15 16k devices) until the upstream `youtubedl-android` maintainer recompiles the FFmpeg binaries with 16k page alignment.
