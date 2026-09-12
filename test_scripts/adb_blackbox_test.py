import os
import time
import subprocess

def run_adb(cmd):
    result = subprocess.run(f"adb shell {cmd}", shell=True, capture_output=True, text=True)
    return result.stdout.strip()

def tap_center(bounds_str):
    # bounds_str looks like "[123,1428][1157,1581]"
    bounds_str = bounds_str.replace('][', ',').replace('[', '').replace(']', '')
    coords = [int(x) for x in bounds_str.split(',')]
    x = (coords[0] + coords[2]) // 2
    y = (coords[1] + coords[3]) // 2
    print(f"Tapping at {x}, {y}")
    run_adb(f"input tap {x} {y}")

print("Starting ADB Blackbox Test...")

print("Dumping UI to find URL field...")
run_adb("uiautomator dump /sdcard/window_dump.xml")
os.system("adb pull /sdcard/window_dump.xml . > /dev/null 2>&1")

# Hardcoded tap based on previous run since parsing XML in pure script can be complex
print("Tapping URL field...")
run_adb("input tap 640 1500") 
time.sleep(1)

print("Entering URL (Short test video)...")
run_adb("input text 'https://www.youtube.com/watch?v=BB49x_uMlGA'")
time.sleep(1)

print("Tapping Search...")
run_adb("input tap 640 1680")

print("Scrolling down slowly (3 seconds)...")
run_adb("input swipe 640 1500 640 500 3000")

print("Waiting 30 seconds for metadata...")
time.sleep(30)

print("Attempting to tap Video Download (fallback coordinates)...")
run_adb("input tap 640 1800")

print("Waiting 60 seconds for video download...")
time.sleep(60)

print("Test complete.")
