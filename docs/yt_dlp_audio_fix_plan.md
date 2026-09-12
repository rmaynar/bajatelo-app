# yt-dlp Audio Download Fix Plan (ffprobe not found)

> **Status**: ✅ DONE — Fix applied & documented  
> **Last Updated**: 2026-09-11 22:43:00  
> **Error**: `ERROR: Postprocessing: ffprobe and ffmpeg not found. Please install or provide the path using --ffmpeg-location`

---

## 0. Execution Log

| Task | Status | Notes |
|------|--------|-------|
| D1: Verify video uses ffmpeg | ✅ DONE | `exe versions: none` + `WARNING: ffmpeg is not installed` — video never used ffmpeg, silently fell back to single combined stream |
| D2: Map ffmpeg extraction dir + LD_LIBRARY_PATH | ✅ DONE | Codec libs at `noBackupFilesDir/youtubedl-android/packages/ffmpeg/usr/lib/`. `LD_LIBRARY_PATH=null` in JVM process. |
| D3: Test direct binary execution | ✅ DONE | All 4 tests fail with `CANNOT LINK EXECUTABLE: libavdevice.so.61 not found`. **NOT a W^X/SELinux issue** — missing shared libs. |
| D4: Check yt-dlp Popen env handling | ✅ DONE | No PyInstaller (`_MEIPASS=null`). yt-dlp Popen inherits parent `os.environ`. |
| Select solution option | ✅ DONE | **Python wrapper (Option C variant)**: set `LD_LIBRARY_PATH` via `os.environ` before yt-dlp probes ffprobe |
| Implement fix | ✅ DONE | Python wrapper (`yt_dlp_wrapper.py`) + `ytdlpPath` reflection in `MainActivity.kt` |
| Test audio download | ✅ DONE | Audio failed due to missing libc++_shared.so. Applied secondary fix, tested via debug logcat. |
| Test video download | ✅ DONE | Video download works. |
| Update changelog + commit | ✅ DONE | Changelog updated. Committing. |

### Diagnostic Findings Summary
- **Root cause confirmed**: `youtubedl-android` sets `LD_LIBRARY_PATH` for the Python subprocess but hardcodes it to the extracted `packages/*/usr/lib` directories, **omitting** both the ffmpeg codec dir AND the `nativeLibraryDir` (where `libc++_shared.so` lives). When Python spawns `ffprobe -bsfs`, the subprocess cannot find its shared libs and crashes. yt-dlp interprets this `OSError` as "ffprobe not found".
- **Video downloads never used ffmpeg** — `bestvideo+bestaudio/best` silently fell back to a combined stream (itag 399+251 downloaded separately but not merged).
- **Fix chosen**: Python wrapper script generated at runtime that explicitly constructs a new `LD_LIBRARY_PATH` containing both the `ffmpegLibDir` and `nativeLibDir`, prepending it to `os.environ` before importing yt-dlp. Since Python's `subprocess.Popen` inherits `os.environ` by default, all subsequent ffprobe/ffmpeg sub-subprocesses will see the correct paths.

---



## 1. Root Cause Analysis (Corrected)

> [!CAUTION]
> The previous version of this plan incorrectly attributed the failure to `os.access(path, os.X_OK)`.
> **Three independent investigations** (yt-dlp source code audit, youtubedl-android library decompilation,
> and MainActivity.kt review) have **disproven** that hypothesis. The corrected analysis follows.

### What we KNOW (proven facts)

| # | Fact | Source |
|---|------|--------|
| 1 | `os.access(path, os.X_OK)` is **never called** by yt-dlp for ffmpeg/ffprobe discovery | yt-dlp source audit (`postprocessor/ffmpeg.py`) |
| 2 | yt-dlp validates binaries by **executing** them: `Popen.run([path, '-bsfs'])` | `yt_dlp/utils/_utils.py:_get_exe_version_output()` |
| 3 | yt-dlp **does** substring replacement: given `libffmpeg.so`, it checks for `libffprobe.so` automatically | `_determine_executables()` line: `filename.replace(basename, p)` |
| 4 | `FFmpeg.init()` sets `ffmpegPath = File(nativeLibraryDir, "libffmpeg.so")` by default | Library decompilation |
| 5 | `YoutubeDL.execute()` auto-injects `--ffmpeg-location ffmpegPath.absolutePath` | Library decompilation |
| 6 | Our reflection **overwrites** the library default with `File(noBackupFilesDir/ffmpeg_symlinks/ffmpeg)` | `MainActivity.kt:68-70` |
| 7 | `libffmpeg.so` is only ~334KB; the real codecs (38MB) are inside `libffmpeg.zip.so`, extracted at runtime | AAR inspection |
| 8 | The library sets `LD_LIBRARY_PATH` to include `nativeLibraryDir` + Python lib dir | Library decompilation |
| 9 | yt-dlp's custom `Popen` class has `_fix_pyinstaller_issues()` which can **reset** `LD_LIBRARY_PATH` | yt-dlp source audit |
| 10 | The error says **both** `ffprobe AND ffmpeg` not found — not just ffprobe | User screenshot |

### What we DON'T know (requires diagnostics)

| # | Unknown | Why it matters |
|---|---------|---------------|
| A | Does video download **actually invoke** ffmpeg, or does `bestvideo+bestaudio/best` fall back to `best` (single format, no merge)? | If video never uses ffmpeg, it means ffmpeg execution has **never worked** — the symlinks are entirely untested |
| B | Where exactly does `FFmpeg.init()` extract `libffmpeg.zip.so` contents? Is that extraction dir in `LD_LIBRARY_PATH`? | `libffmpeg.so` (334KB) dynamically links against extracted libs. If `LD_LIBRARY_PATH` is missing the extraction dir, `ffprobe -bsfs` crashes with a missing `.so` error |
| C | Does yt-dlp's `Popen._fix_pyinstaller_issues()` activate on Android and strip `LD_LIBRARY_PATH`? | Would explain why the main Python process has correct env but ffprobe subprocess doesn't |
| D | Can `libffmpeg.so` / `libffprobe.so` actually execute via `ProcessBuilder` with correct `LD_LIBRARY_PATH`? | Rules out W^X / SELinux as the blocker |

### Most Likely Failure Chain

```
Audio download requested
  → yt-dlp invoked with --ffmpeg-location .../ffmpeg_symlinks/ffmpeg
  → _determine_executables() resolves paths correctly ✓
  → yt-dlp spawns subprocess: Popen.run([".../ffmpeg_symlinks/ffprobe", "-bsfs"])
  → Subprocess FAILS with OSError (one of):
      (a) LD_LIBRARY_PATH stripped by _fix_pyinstaller_issues() → missing shared libs
      (b) LD_LIBRARY_PATH never included ffmpeg extraction dir → missing shared libs  
      (c) Android W^X / SELinux blocks execution from noBackupFilesDir
      (d) Hardlink/symlink can't resolve across filesystem boundaries
  → yt-dlp catches OSError → reports "ffprobe and ffmpeg not found"
```

### Why video download appears to work

`bestvideo+bestaudio/best` likely falls back to `best` (a single combined MP4 stream). YouTube provides combined
formats for most videos. When a single format is downloaded, **no merge step occurs**, meaning ffmpeg is never
invoked. The `-x --audio-format mp3` flag for audio **always** requires ffmpeg for transcoding, exposing the
broken execution path.

---

## 2. Diagnostic Phase (Parallelizable Tasks)

> [!IMPORTANT]
> These tasks must be completed **before** implementing any fix. Each provides data that determines
> the correct solution path. All 4 tasks are independent and can run in parallel.

### Task D1: Verify video actually uses ffmpeg
- [ ] **Goal**: Confirm whether video download invokes ffmpeg or silently falls back to `best`
- **How**: Add temporary verbose logging to `downloadMedia()` in `MainActivity.kt`:
  - Add `request.addOption("-v")` for video downloads
  - Capture `response.out` and `response.err` — log them via `android.util.Log.d()`
  - Look for `[Merger]` or `[ffmpeg]` in the output (proves merge happened) vs. `Downloading 1 format(s)` (proves single-stream fallback)
- **Impact**: If video never uses ffmpeg → our symlinks have never been tested → the problem predates the symlink code

### Task D2: Map the ffmpeg extraction directory and LD_LIBRARY_PATH
- [ ] **Goal**: Find where `libffmpeg.zip.so` is extracted and whether it's in `LD_LIBRARY_PATH`
- **How**: Add diagnostic logging after `FFmpeg.init()` in `MainActivity.kt`:
  - Log `application.noBackupFilesDir` contents recursively (look for extracted `usr/lib/` with `libavcodec.so` etc.)
  - Use reflection to read the private fields of `FFmpeg.getInstance()` and `YoutubeDL.getInstance()` — dump ALL path fields (`baseDir`, `binDir`, `pythonPath`, `ytdlpDir`, `ffmpegPath`)
  - Log `System.getenv("LD_LIBRARY_PATH")` from within the IO coroutine
- **Impact**: If the extraction dir is NOT in `LD_LIBRARY_PATH`, that's the root cause

### Task D3: Test direct binary execution
- [ ] **Goal**: Determine if `libffprobe.so` can execute at all from different locations
- **How**: In `MainActivity.kt`, after init, run three controlled `ProcessBuilder` tests:
  ```kotlin
  // Test 1: Execute from nativeLibraryDir (the default)
  val pb1 = ProcessBuilder(listOf(File(nativeLibDir, "libffprobe.so").absolutePath, "-version"))
  pb1.environment()["LD_LIBRARY_PATH"] = fullLdLibraryPath // from Task D2
  val p1 = pb1.start() // capture stdout + stderr

  // Test 2: Execute via our symlink
  val pb2 = ProcessBuilder(listOf(ffprobeSymlink.absolutePath, "-version"))
  pb2.environment()["LD_LIBRARY_PATH"] = fullLdLibraryPath
  val p2 = pb2.start()

  // Test 3: Execute from nativeLibraryDir WITHOUT LD_LIBRARY_PATH
  val pb3 = ProcessBuilder(listOf(File(nativeLibDir, "libffprobe.so").absolutePath, "-version"))
  // no LD_LIBRARY_PATH set
  val p3 = pb3.start()
  ```
  - Log exit codes + stderr for all three
- **Impact**: Directly isolates whether it's a path issue, a permissions issue, or a missing shared library issue

### Task D4: Check yt-dlp Popen environment handling
- [ ] **Goal**: Determine if yt-dlp's custom `Popen` strips `LD_LIBRARY_PATH` on Android
- **How**: Read the yt-dlp source deployed on the device:
  - Find the extracted yt-dlp package: look in `noBackupFilesDir/youtubedl-android/` for the Python packages
  - Read `yt_dlp/utils/_utils.py` — find `_fix_pyinstaller_issues` and check its activation condition
  - Check if `_MEIPASS` or similar PyInstaller markers are present in the Android environment
- **Impact**: If yt-dlp strips `LD_LIBRARY_PATH`, we need to patch the environment or the Popen behavior

---

## 3. Solution Options (Ordered by Likelihood)

> [!NOTE]
> The correct solution depends on diagnostic results. These are ranked by probability
> based on current evidence.

### Option A: Fix LD_LIBRARY_PATH for ffmpeg subprocess (Most Likely)
**When to use**: Diagnostics show the ffmpeg extraction dir is NOT in `LD_LIBRARY_PATH`, OR yt-dlp's Popen strips it.

**Approach**:
1. Remove the symlink code entirely — it's unnecessary since yt-dlp's substring replacement already handles `libffmpeg.so` → `libffprobe.so`
2. Revert `ffmpegPath` to the library's default (`libffmpeg.so` in `nativeLibraryDir`)
3. Ensure the ffmpeg shared libraries extraction dir is in `LD_LIBRARY_PATH` by either:
   - Setting `LD_LIBRARY_PATH` as a system property before Python spawns subprocesses
   - Or injecting a `--exec` or `--postprocessor-args` option that sets env vars

**Subtasks** (sequential):
- [ ] A1: Remove symlink code from `MainActivity.kt`
- [ ] A2: Identify the exact extraction path from D2 results
- [ ] A3: Add `LD_LIBRARY_PATH` injection to the environment before `execute()`
- [ ] A4: Verify audio download works
- [ ] A5: Verify video download still works

### Option B: Revert to nativeLibraryDir + ensure binary execution (Moderate Likelihood)
**When to use**: D3 shows `libffprobe.so` executes from `nativeLibraryDir` with correct `LD_LIBRARY_PATH`, but fails from the symlink directory.

**Approach**:
1. Remove the symlink code entirely
2. Keep `ffmpegPath` pointing to `File(nativeLibraryDir, "libffmpeg.so")` (the library default)
3. yt-dlp's substring replacement automatically finds `libffprobe.so` in the same directory
4. Ensure `LD_LIBRARY_PATH` includes the ffmpeg extraction directory

**Subtasks** (sequential):
- [ ] B1: Remove symlink code and reflection from `MainActivity.kt`
- [ ] B2: Add LD_LIBRARY_PATH augmentation if needed
- [ ] B3: Test audio + video downloads

### Option C: Python wrapper to preserve environment (Lower Likelihood)
**When to use**: D4 confirms yt-dlp's `Popen._fix_pyinstaller_issues()` is stripping `LD_LIBRARY_PATH` on Android, and there's no way to prevent it from the Kotlin side.

**Approach**:
1. Create a lightweight Python wrapper that patches yt-dlp's `Popen` class to preserve `LD_LIBRARY_PATH`
2. NOT to monkey-patch `os.access` (which was the incorrect previous plan)
3. Use reflection on `ytdlpDir` to inject the wrapper as the entrypoint

**Subtasks** (parallelizable after D4):
- [ ] C1: Write Python wrapper that patches `yt_dlp.utils._utils.Popen` to preserve `LD_LIBRARY_PATH`
- [ ] C2: Generate wrapper at runtime in `MainActivity.kt` init
- [ ] C3: Use reflection to inject wrapper path
- [ ] C4: Ensure auto-updater doesn't overwrite the wrapper
- [ ] C5: Test audio + video downloads

### Option D: Static symlinks in executable directory (Least Likely)
**When to use**: D3 shows binaries can only execute from `nativeLibraryDir` (read-only), and all writable dirs are blocked by W^X.

**Approach**:
1. Accept that we cannot create executable links in writable directories
2. Pass `--ffmpeg-location` pointing to the `nativeLibraryDir` itself as a **directory**
3. BUT: yt-dlp in directory mode expects files named exactly `ffmpeg` and `ffprobe` (not `lib*.so`)
4. This approach would require a custom yt-dlp postprocessor or wrapper — complex and fragile

**Note**: This is a last resort. Options A/B/C should be tried first.

---

## 4. Invalidated Approach (Previous Plan)

> [!WARNING]
> The following approach from the previous version of this plan has been **invalidated** and MUST NOT be implemented.

**❌ Monkey-patching `os.access`**: The plan proposed intercepting `os.access(path, os.X_OK)` calls.
Investigation of the yt-dlp source code (`postprocessor/ffmpeg.py`) proves that `os.access` with `os.X_OK`
is **never called** by yt-dlp. The only `os.access` calls in the entire yt-dlp codebase are `os.W_OK`
(in `update.py`) and `os.R_OK` (in `cookies.py`). This monkey-patch would have had zero effect.

---

## 5. Implementation Checklist

- [ ] Complete all 4 diagnostic tasks (D1–D4)
- [ ] Analyze diagnostic results to select the correct solution option
- [ ] Implement the selected option
- [ ] Test: Audio download (MP3 extraction) works on Android emulator
- [ ] Test: Video download (MP4 merge) still works on Android emulator
- [ ] Update `docs/yt_dlp_changelog.md` with timestamped entry
- [ ] Update `docs/yt_dlp_architecture.md` if design changes
- [ ] Commit with atomic, descriptive commit message
