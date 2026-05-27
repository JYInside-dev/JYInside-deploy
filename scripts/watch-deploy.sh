#!/usr/bin/env bash

set -e

BASE_DIR="/opt/deploy-repo/community-deploy"
REQUEST_FILE="$BASE_DIR/service-server/ops/deploy-request.txt"
DEPLOY_SCRIPT="$BASE_DIR/scripts/switching.sh"
LOG_FILE="$BASE_DIR/service-server/ops/watch-deploy.log"

mkdir -p "$BASE_DIR/service-server/ops"
# 타임스탬프 변경 또는 빈 파일 생성 명령어
touch "$LOG_FILE"

# 감시 시작 로그 남기기
echo "$(date '+%F %T') watch-deploy started" >> "$LOG_FILE"

while true; do
  # 요청 파일 존재 여부 확인
  if [ -f "$REQUEST_FILE" ]; then
    # 요청 감지 로그
    echo "$(date '+%F %T') deploy request detected" >> "$LOG_FILE"

    # 요청 파일에서 TARGET=blue 또는 TARGET=green 읽기
    TARGET=$(sed -n 's/^TARGET=//p' "$REQUEST_FILE" | head -n 1 | tr -d '\r\n ')

    echo "$(date '+%F %T') target from request file: $TARGET" >> "$LOG_FILE"

    # target 검증
    if [ "$TARGET" != "blue" ] && [ "$TARGET" != "green" ]; then
      echo "$(date '+%F %T') invalid target: $TARGET" >> "$LOG_FILE"
      echo "$(date '+%F %T') request file content:" >> "$LOG_FILE"
      cat "$REQUEST_FILE" >> "$LOG_FILE" 2>&1

      rm -f "$REQUEST_FILE"
      echo "$(date '+%F %T') invalid request file removed" >> "$LOG_FILE"

      sleep 2
      continue
    fi

    # 요청 파일 삭제 (안지우면 배포 무한 반복 실행할 수도 있음)
    rm -f "$REQUEST_FILE"

    # 배포 스크립트 실행 여부 기록
    echo "$(date '+%F %T') changing directory to $BASE_DIR" >> "$LOG_FILE"
    cd "$BASE_DIR"

    echo "$(date '+%F %T') running switching script: $DEPLOY_SCRIPT $TARGET" >> "$LOG_FILE"

    # 실제 배포 스크립트 실행 (성공, 실패 로그 전부 기록)
    if bash "$DEPLOY_SCRIPT" "$TARGET" >> "$LOG_FILE" 2>&1; then
      echo "$(date '+%F %T') deploy success. target=$TARGET" >> "$LOG_FILE"
    else
      echo "$(date '+%F %T') deploy failed. target=$TARGET" >> "$LOG_FILE"
    fi
  fi

  sleep 2
done