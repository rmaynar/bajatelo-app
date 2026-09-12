---
name: testapp
description: >-
  Executes the automated UI test suite for the Bajatelo application, handling YouTube downloads via ADB and Flutter Integration Tests.
---

# Bajatelo App Testing Skill

This skill provides instructions for the agent to test the video and audio downloading flow of the Bajatelo app.

The test flow executes the following steps:
1. Open the application.
2. Enter the URL `https://www.youtube.com/watch?v=BB49x_uMlGA` into the search box.
3. Click the "Search" (Buscar) button.
4. Slowly scroll down and wait 30 seconds for the metadata and download buttons to appear.
5. Tap "Download Video (MP4)".
6. Wait 1 minute for the video processing/downloading to complete.
7. Capture logs via logcat.
8. Write the test results to `test_reports/download_test_results.md`.

## Available Testing Methods

The agent supports two testing methods. Always prefer the **Flutter Integration Test** (Method 1) unless the user specifically asks for the ADB script (Method 2).

### Method 1: Flutter Integration Test (Recommended)
This uses the official Flutter `integration_test` framework, providing robust UI driving and assertions without relying on brittle ADB coordinates.
- **Test File**: `integration_test/download_flow_test.dart`
- **Command to run**: `rtk flutter test integration_test/download_flow_test.dart`

### Method 2: Pure ADB UIAutomator Script
This is a python black-box script that uses `adb shell uiautomator dump` and `adb shell input tap`. It is brittle and depends on screen layout.
- **Script File**: `test_scripts/adb_blackbox_test.py`
- **Command to run**: `python3 test_scripts/adb_blackbox_test.py`

## Instructions for the Agent
1. Determine which method to use based on the user's request (default to Method 1).
2. Start clearing the logcat: `rtk adb logcat -c`
3. Start the permission auto-clicker in the background to click "Allow" on any popups: `bash test_scripts/auto_allow_permissions.sh &`
4. Execute the chosen test command.
5. While testing or immediately after, fetch the logcat output.
6. Create or append the test results (including success/failure and relevant logcat snippets) to `test_reports/download_test_results.md`.
