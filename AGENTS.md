# RTK (Rust Token Killer)

Prefix every shell command with `rtk`:
- `rtk git status`, `rtk git diff`, `rtk git log`
- `rtk flutter test`, `rtk flutter analyze`
- `rtk ls ...`, `rtk tree ...`
- Keep the prefix inside chains: `rtk git add . && rtk git commit -m "msg"`
- Commands that RTK does not have a dedicated filter for will safely pass through as-is.

# Command Output

Command output here is condensed to save tokens, keeping every signal and dropping costly noise.
- Treat it as the complete result: run commands normally, and batch related commands into one call to avoid extra turns.
- Truncated results state their recovery path in their own output.
- Re-run a command as `rtk proxy <cmd>` only when its result is unusable: empty when output was clearly expected, contradicting its exit code, or garbled.

## Key RTK Utilities
- `rtk gain` / `rtk gain --history` — token savings summary.
- `rtk proxy <cmd>` — run a command unfiltered, still tracked.
- `RTK_DISABLED=1 <cmd>` — skip RTK for a specific command.

# yt-dlp / Downloading Investigations
For any tasks, issues, or investigations involving video downloading, audio downloading, ffmpeg, or the yt-dlp engine:
- **MANDATORY**: You MUST read `docs/yt_dlp_architecture_and_fixes.md` FIRST before making any plans, proposing fixes, or executing codebase changes. It contains crucial historical context, architectural decisions, and native Android quirks (like `libffprobe.so` symlink bypasses) that will save you time and prevent regressions.
