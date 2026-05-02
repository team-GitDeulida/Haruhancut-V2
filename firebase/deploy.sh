#!/usr/bin/env bash
# https://console.cloud.google.com/run/services?authuser=0&hl=ko&project=haruhancut-kor

# 파이어베이스 로그인 초기화
# firebase logout
# firebase login --reauth

# 접근 가능한 프로젝트 확인
# firebase projects:list

# 에러, 미정의 변수, 파이프 실패가 나면 즉시 종료합니다.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTIONS_DIR="$SCRIPT_DIR/functions"

# 배포를 위해 Firebase CLI가 설치되어 있어야 합니다.
if ! command -v firebase >/dev/null 2>&1; then
  echo "firebase CLI가 설치되어 있지 않습니다."
  echo "npm install -g firebase-tools"
  exit 1
fi

# Functions 시크릿과 실행 환경 설정은 이 파일에서 읽습니다.
if [ ! -f "$FUNCTIONS_DIR/.env" ]; then
  echo "functions/.env 파일이 없습니다."
  echo "functions/.env 파일을 만든 뒤 다시 실행해주세요."
  exit 1
fi

# 처음 실행하는 환경이면 functions 의존성을 먼저 설치합니다.
if [ ! -d "$FUNCTIONS_DIR/node_modules" ]; then
  echo "functions 의존성을 먼저 설치합니다..."
  npm --prefix "$FUNCTIONS_DIR" install
fi

# lint가 실패하면 배포하지 않도록 먼저 검사합니다.
echo "functions lint 실행 중..."
npm --prefix "$FUNCTIONS_DIR" run lint

# 기본 Firebase 프로젝트에 Functions만 배포합니다.
echo "Firebase Functions 배포 중..."
firebase deploy --project "$(cd "$SCRIPT_DIR" && cat .firebaserc | sed -n 's/.*\"default\": \"\\([^\"]*\\)\".*/\\1/p')" --only functions
