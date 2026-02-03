# chmod +x mac_cache_cleaner.sh
# ./mac_cache_cleaner.sh            # DRY RUN (안전하게 미리보기)
# ./mac_cache_cleaner.sh --apply    # 실제 삭제
# ./mac_cache_cleaner.sh --xcode-only --apply

#!/usr/bin/env bash
set -euo pipefail

# =========================
# mac_cache_cleaner.sh
# - 기본: DRY RUN (삭제 안 함)
# - 실제 삭제: --apply
# - 옵션:
#   --apply           실제 삭제 수행
#   --xcode-only      Xcode 관련 캐시만
#   --dev-only        개발도구 캐시만 (xcode 포함)
#   --all             가능한 항목 전부 (기본과 동일하지만 의도를 명확히)
#   --no-confirm      확인 없이 진행 (apply일 때만 의미)
#   -h|--help         도움말
# =========================

APPLY=0
CONFIRM=1
MODE="all"  # all | xcode-only | dev-only

for arg in "${@:-}"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --no-confirm) CONFIRM=0 ;;
    --xcode-only) MODE="xcode-only" ;;
    --dev-only) MODE="dev-only" ;;
    --all) MODE="all" ;;
    -h|--help)
      cat <<'EOF'
Usage:
  bash mac_cache_cleaner.sh [options]

Options:
  --apply         실제 삭제 수행 (기본은 DRY RUN)
  --xcode-only    Xcode 캐시만 정리
  --dev-only      개발도구 캐시만 정리 (Xcode 포함)
  --all           가능한 항목 전부 정리 (기본)
  --no-confirm    (apply일 때) 확인 질문 없이 진행
  -h, --help      도움말
EOF
      exit 0
      ;;
  esac
done

# ---------- pretty output ----------
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
GRAY="\033[90m"

icon_ok="✅"
icon_warn="⚠️"
icon_run="🧹"
icon_dry="🧪"
icon_info="ℹ️"
icon_del="🗑️"

hr() { printf "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"; }
title() { printf "\n${BOLD}${CYAN}%s${RESET}\n" "$1"; }
sub() { printf "${DIM}%s${RESET}\n" "$1"; }
ok() { printf "${GREEN}%s${RESET} %s\n" "$icon_ok" "$1"; }
warn() { printf "${YELLOW}%s${RESET} %s\n" "$icon_warn" "$1"; }
info() { printf "${CYAN}%s${RESET} %s\n" "$icon_info" "$1"; }
runmsg() { printf "${CYAN}%s${RESET} %s\n" "$icon_run" "$1"; }

bytes_to_human() {
  # 입력: 바이트 정수
  local b=$1
  local units=(B KB MB GB TB)
  local i=0
  local val=$b
  while (( val >= 1024 && i < ${#units[@]}-1 )); do
    val=$(( val / 1024 ))
    i=$(( i + 1 ))
  done
  printf "%s %s" "$val" "${units[$i]}"
}

get_dir_size_bytes() {
  local path="$1"
  if [[ -e "$path" ]]; then
    # du -sk: KB 단위
    local kb
    kb=$(du -sk "$path" 2>/dev/null | awk '{print $1}' || echo 0)
    echo $(( kb * 1024 ))
  else
    echo 0
  fi
}

safe_rm_rf() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    return 0
  fi

  if (( APPLY == 0 )); then
    printf "  ${DIM}${icon_dry} DRY  ${RESET}%s\n" "$path"
  else
    printf "  ${RED}${icon_del} DEL  ${RESET}%s\n" "$path"
    rm -rf "$path"
  fi
}

confirm_or_exit() {
  if (( APPLY == 0 )); then
    return 0
  fi
  if (( CONFIRM == 0 )); then
    return 0
  fi
  echo
  warn "실제 삭제(--apply) 모드입니다. 캐시 삭제로 인해:"
  sub "- 일부 앱이 다시 로그인 요구 / 느려질 수 있음 (재빌드/재다운로드 발생)"
  sub "- Xcode 캐시 삭제 시 첫 빌드가 오래 걸릴 수 있음"
  echo
  read -r -p "계속할까요? (y/N): " ans
  if [[ "${ans,,}" != "y" ]]; then
    warn "취소했습니다."
    exit 0
  fi
}

# ---------- targets ----------
declare -a TARGETS=()

# 공통(사용자 캐시/로그 일부)
COMMON_TARGETS=(
  "$HOME/Library/Caches/*"
  "$HOME/Library/Logs/*"
  "$HOME/Library/Application Support/CrashReporter/*"
  "$HOME/Library/Developer/CoreSimulator/Caches/*"
)

# Xcode 관련
XCODE_TARGETS=(
  "$HOME/Library/Developer/Xcode/DerivedData"
  "$HOME/Library/Developer/Xcode/Archives"
  "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
  "$HOME/Library/Developer/Xcode/Products"
  "$HOME/Library/Developer/Xcode/ModuleCache.noindex"
  "$HOME/Library/Developer/Xcode/Build"
)

# 개발도구 캐시(있으면 정리)
DEV_TARGETS=(
  "$HOME/.swiftpm/cache"
  "$HOME/Library/Caches/org.swift.swiftpm"
  "$HOME/Library/Caches/CocoaPods"
  "$HOME/Library/Caches/pip"
  "$HOME/.npm/_cacache"
  "$HOME/Library/Caches/Yarn"
  "$HOME/Library/Caches/pnpm"
)

# 모드별 구성
case "$MODE" in
  xcode-only)
    TARGETS+=("${XCODE_TARGETS[@]}")
    ;;
  dev-only)
    TARGETS+=("${XCODE_TARGETS[@]}")
    TARGETS+=("${DEV_TARGETS[@]}")
    ;;
  all)
    TARGETS+=("${COMMON_TARGETS[@]}")
    TARGETS+=("${XCODE_TARGETS[@]}")
    TARGETS+=("${DEV_TARGETS[@]}")
    ;;
esac

# ---------- summary ----------
title "macOS Cache Cleaner"
hr
info "모드: ${MODE}"
if (( APPLY == 0 )); then
  ok "실행 방식: DRY RUN (삭제하지 않음)  → 실제 삭제는 --apply"
else
  warn "실행 방식: APPLY (실제 삭제)"
fi

# Homebrew cache는 명령으로 처리하는 게 안전해서 별도로
HAS_BREW=0
if command -v brew >/dev/null 2>&1; then
  HAS_BREW=1
  info "Homebrew 감지됨: brew cleanup 가능"
fi

# 용량 계산(대략)
hr
runmsg "정리 대상 용량(대략) 계산 중..."
TOTAL=0
for p in "${TARGETS[@]}"; do
  # glob 패턴 처리 위해 eval + for
  # shellcheck disable=SC2086
  for expanded in $p; do
    sz=$(get_dir_size_bytes "$expanded")
    TOTAL=$(( TOTAL + sz ))
  done
done
ok "예상 정리 용량(대략): $(bytes_to_human "$TOTAL")"
sub "(Caches/* 같은 패턴은 시스템 상태에 따라 편차가 큼)"

confirm_or_exit

# ---------- cleaning ----------
echo
title "Cleaning"
hr

# 파일 삭제(패턴 포함)
for p in "${TARGETS[@]}"; do
  # shellcheck disable=SC2086
  for expanded in $p; do
    # 위험한 루트/홈 보호
    if [[ "$expanded" == "/" || "$expanded" == "$HOME" ]]; then
      warn "보호 경로 스킵: $expanded"
      continue
    fi
    safe_rm_rf "$expanded"
  done
done

# brew cleanup
if (( HAS_BREW == 1 )); then
  echo
  title "Homebrew"
  hr
  if (( APPLY == 0 )); then
    printf "  ${DIM}${icon_dry} DRY  ${RESET}brew cleanup -s\n"
  else
    printf "  ${RED}${icon_del} RUN  ${RESET}brew cleanup -s\n"
    brew cleanup -s >/dev/null 2>&1 || true
  fi
fi

# 시스템 캐시 flush는 권장하지 않아서 안내만
echo
hr
if (( APPLY == 0 )); then
  ok "DRY RUN 완료. 실제 삭제하려면:"
  echo "  bash mac_cache_cleaner.sh --apply"
else
  ok "정리 완료."
fi

echo
info "팁"
sub "- Xcode 관련만 하고 싶으면: --xcode-only"
sub "- 개발도구 위주면: --dev-only"
sub "- 캐시 정리 후 첫 실행/첫 빌드는 느릴 수 있어요."
