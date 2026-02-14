#!/bin/bash
set -e

echo "🧩 Generating project..."
tuist generate --no-open

SIM_NAME="iphone 16 Pro Max"
SIM_OS="18.5"

UDID=$(xcrun simctl list devices available | \
  grep "iOS ${SIM_OS}" -A 20 | \
  grep "${SIM_NAME}" | \
  head -n 1 | \
  sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')

xcrun simctl bootstatus "$UDID" -b

# 🔵 1️⃣ App 기준으로 전체 빌드 1회
echo "🔵 Build for testing..."
xcodebuild build-for-testing \
  -workspace Haruhancut.xcworkspace \
  -scheme App \
  -configuration Debug \
  -destination "id=$UDID"

# 🟢 2️⃣ Core
echo "🟢 Core tests..."
xcodebuild test-without-building \
  -workspace Haruhancut.xcworkspace \
  -scheme Core \
  -destination "id=$UDID"

# 🟢 3️⃣ Data
echo "🟢 Data tests..."
xcodebuild test-without-building \
  -workspace Haruhancut.xcworkspace \
  -scheme Data \
  -destination "id=$UDID"

# 🟢 4️⃣ App
echo "🟢 App tests..."
xcodebuild test-without-building \
  -workspace Haruhancut.xcworkspace \
  -scheme App \
  -destination "id=$UDID" \
  -parallel-testing-enabled YES \
  -parallel-testing-worker-count 4

echo "✅ All tests finished!"
