#!/usr/bin/env bash

set -e

BASE_DIR="/opt/deploy-repo/community-deploy"
OPS_DIR="$BASE_DIR/service-server/ops"
REQUEST_FILE="$OPS_DIR/deploy-request.txt"
DEPLOY_SCRIPT="$BASE_DIR/scripts/switching.sh"
LOG_FILE="$OPS_DIR/watch-deploy.log"

mkdir -p "$OPS_DIR"
# 타임스탬프 변경 또는 빈 파일 생성 명령어
touch "$LOG_FILE"

# 감시 시작 로그 남기기
log() {
  echo "$(date '+%F %T') $1" >> "$LOG_FILE"
}

log "watch-deploy started"
log "BASE_DIR=$BASE_DIR"
log "REQUEST_FILE=$REQUEST_FILE"
log "DEPLOY_SCRIPT=$DEPLOY_SCRIPT"
log "LOG_FILE=$LOG_FILE"

while true; do
  # 요청 파일 존재 여부 확인
  if [ -f "$REQUEST_FILE" ]; then
    # 요청 감지 로그
    log "deploy request detected"

    # 요청 파일에서 TARGET=blue 또는 TARGET=green 읽기
    TARGET=$(sed -n 's/^TARGET=//p' "$REQUEST_FILE" | head -n 1 | tr -d '\r\n ')

    log "target from request file: $TARGET"

    # target 검증
    if [ "$TARGET" != "blue" ] && [ "$TARGET" != "green" ]; then
      log "invalid target: $TARGET"
      log "request file content:"
      cat "$REQUEST_FILE" >> "$LOG_FILE" 2>&1

      rm -f "$REQUEST_FILE"
      log "invalid request file removed"

      sleep 2
      continue
    fi

    # 요청 파일 삭제 (안지우면 배포 무한 반복 실행할 수도 있음)
    rm -f "$REQUEST_FILE"
    # 배포 스크립트 실행 여부 기록
    log "request file removed"

    cd "$BASE_DIR"
    log "changed directory to $BASE_DIR"

    if [ ! -f "$DEPLOY_SCRIPT" ]; then
      log "deploy script not found: $DEPLOY_SCRIPT"
      sleep 2
      continue
    fi

    log "running switching script: bash $DEPLOY_SCRIPT $TARGET"

    # 실제 배포 스크립트 실행 (성공, 실패 로그 전부 기록)
    if bash "$DEPLOY_SCRIPT" "$TARGET" >> "$LOG_FILE" 2>&1; then
      log "deploy success. target=$TARGET"
    else
      log "deploy failed. target=$TARGET"
    fi
  fi

  sleep 2
done