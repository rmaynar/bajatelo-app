#!/bin/bash
# Runs in the background and attempts to click "Allow" on permission dialogs
echo "Starting permission auto-clicker..."
for i in {1..30}; do
    # On Android, keyevent 22 is KEYCODE_DPAD_RIGHT and 66 is KEYCODE_ENTER
    # We can use uiautomator to find the exact button, but it's slow.
    # We'll just try to tap the standard location for "Allow" on Pixel devices.
    # Usually around (x:750, y:1250) or we can use uiautomator if needed.
    
    # Check if a permission dialog is active
    DUMP=$(adb shell dumpsys window | grep -i mCurrentFocus)
    if [[ "$DUMP" == *"Permission"* || "$DUMP" == *"GrantPermissions"* ]]; then
        echo "Permission dialog detected! Clicking Allow..."
        # Try tapping standard coordinates for "Allow"
        adb shell input tap 750 1350
        # Fallback: use D-pad navigation to select Allow and press Enter
        adb shell input keyevent 22
        adb shell input keyevent 22
        adb shell input keyevent 66
    fi
    sleep 2
done
echo "Permission auto-clicker finished."
