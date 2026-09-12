#!/bin/bash

# Start background permission auto-clicker
bash test_scripts/auto_allow_permissions.sh > /dev/null 2>&1 &
PERM_PID=$!

echo "Starting screen recording on device..."
adb shell screenrecord --bit-rate 8000000 /sdcard/demo.mp4 &
# Give it a second to initialize
sleep 2

echo "Running Flutter Integration Test..."
flutter test integration_test/download_flow_test.dart -d emulator-5554

echo "Test finished. Stopping screen recording..."
# Send SIGINT to gracefully stop screenrecord and save the mp4
adb shell pkill -INT screenrecord
sleep 3

echo "Pulling video to host..."
adb pull /sdcard/demo.mp4 ./bajatelo_demo.mp4

# Clean up
kill $PERM_PID
adb shell rm /sdcard/demo.mp4

echo "Video successfully saved to bajatelo_demo.mp4"
