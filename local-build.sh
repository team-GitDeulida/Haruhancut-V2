#!/usr/bin/env bash
set -euo pipefail

# Xcode
echo "🔧 [Xcode] 개발자 디렉토리 설정"
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

echo "📱 [Xcode] 시뮬레이터 설정 중..."
SIMULATOR_NAME="iPhone 16"
SIMULATOR_OS="18.5"

SIMULATOR_UDID=$(xcrun simctl list devices available | \
  grep "iOS ${SIMULATOR_OS}" -A 20 | \
  grep "^ *${SIMULATOR_NAME} (" | \
  head -n 1 | \
  sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')

if [[ -z "$SIMULATOR_UDID" ]]; then
  echo "❌ [Xcode] 시뮬레이터를 찾을 수 없습니다"
  exit 1
fi

echo "✅ [Xcode] 시뮬레이터 선택됨: $SIMULATOR_NAME $SIMULATOR_OS ($SIMULATOR_UDID)"
xcrun simctl bootstatus "$SIMULATOR_UDID" -b > /dev/null
echo

# Tuist
echo "📦 [Tuist] 프로젝트 설정 중..."
tuist install --quiet > /dev/null
if ! tuist generate --no-open > /dev/null 2>&1; then
  echo "❌ [Tuist] 프로젝트 생성 실패"
  exit 1
fi
echo "✅ [Tuist] 프로젝트 생성 완료"
echo

# Core Unit Tests
# echo "🧪 Running Core unit tests"
# xcodebuild test \
#   -workspace Haruhancut.xcworkspace \
#   -scheme Core \
#   -destination "id=$SIMULATOR_UDID" \
#   -derivedDataPath DerivedData \
#   | xcpretty
# echo "✅ Core unit tests completed"
# echo

# Build
echo "🏗️  [Build] 앱 빌드 시작"
xcodebuild build \
  -quiet \
  -workspace Haruhancut.xcworkspace \
  -scheme App \
  -destination "id=$SIMULATOR_UDID" \
  -derivedDataPath DerivedData \
  2> /dev/null | xcpretty
  # | xcpretty
echo "✅ [Build] 앱 빌드 성공"

# =========================
# Tuist Tests
# =========================
echo "🧪 [Test] Core Tests 시작"
tuist test Core \
  --configuration Debug \
  --skip-ui-tests \
  --derived-data-path DerivedData \
  --destination "id=$SIMULATOR_UDID"
echo "✅ [Test] Core Tests 완료"
echo

echo "🧪 [Test] Data Tests 시작"
tuist test Data \
  --configuration Debug \
  --skip-ui-tests \
  --derived-data-path DerivedData \
  --destination "id=$SIMULATOR_UDID"
echo "✅ [Test] Data Tests 완료"
echo

echo "🧪 [Test] App Tests 시작"
tuist test App \
  --configuration Debug \
  --derived-data-path DerivedData \
  --destination "id=$SIMULATOR_UDID"
echo "✅ [Test] App Tests 완료"
echo


# =========================
# Finish
# =========================
echo "🚀 [Xcode] 워크스페이스 열기"
open Haruhancut.xcworkspace
echo

echo "✅ [Success] 로컬 CI가 성공적으로 완료되었습니다"