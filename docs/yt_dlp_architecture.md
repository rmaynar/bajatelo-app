# yt-dlp Architecture Design Concepts

This document tracks the core architectural decisions and implementation concepts for video and audio downloading via `yt-dlp` and `ffmpeg` in this Flutter application.

**⚠️ AGENT RULE: Always read this file FIRST to understand the system design before proposing or making changes to the download engine.**

## 1. Dart / UI Layer
* **State Management**: Uses Riverpod (`download_notifier.dart`, `download_state.dart`). The state tracks raw terminal errors, progress, and whether the engine needs an update.
* **Error Handling**: Raw terminal errors from `yt-dlp` are parsed by `YtdlpErrorParser` (`lib/core/utils/ytdlp_error_parser.dart`). It categorizes known errors (e.g., HTTP 400, DRM, Geo-restrictions) and flags if a `yt-dlp` engine update is recommended.
* **UI**: The user is presented with actionable error banners (e.g., an "Update Engine" button) and an expandable toggle to see raw `stderr` output.

## 2. Native Android Layer (`MainActivity.kt`)
* **Initialization**: The `YoutubeDL` and `FFmpeg` libraries are initialized asynchronously via Kotlin Coroutines (`Dispatchers.IO`) in `onCreate` to prevent Application Not Responding (ANR) crashes.
* **Auto-updater**: On startup, the app attempts a best-effort, non-blocking update of the `yt-dlp` binary (`YoutubeDL.getInstance().updateYoutubeDL(application)`).
* **Platform Channels**: `AndroidDownloaderService` communicates with `MainActivity.kt` via MethodChannels (`getVideoInfo`, `downloadMedia`, `updateEngine`).

## 3. Core Engine Dependency
* **Fork Choice**: We use the community-maintained `io.github.junkfood02.youtubedl-android` fork (over the original `yausername` library) because it bundles Python 3.10+, which is strictly required by modern `yt-dlp` releases.
