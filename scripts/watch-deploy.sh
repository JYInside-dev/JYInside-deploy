#!/usr/bin/env bash

set -e

BASE_DIR="/mnt/c/DH_cloud_backend/SW-project/SW-project-deploy"
REQUEST_FILE="$BASE_DIR/ops/deploy-request.txt"
DEPLOY_SCRIPT="$BASE_DIR/scripts/deploy.sh"
LOG_FILE="$BASE_DIR/ops/watch-deploy.log"

mkdir -p "$BASE_DIR/ops"
# 타임스탬프 변경 또는 빈 파일 생성 명령어
touch "$LOG_FILE"

# 감시 시작 로그 남기기
echo "$(date '+%F %T') watch-deploy started" >> "$LOG_FILE"

while true; do
  # 요청 파일 존재 여부 확인
  if [ -f "$REQUEST_FILE" ]; then
    # 요청 감지 로그
    echo "$(date '+%F %T') deploy request detected" >> "$LOG_FILE"
    # 요청 파일 삭제 (안지우면 배포 무한 반복 실행할 수도 있음)
    rm -f "$REQUEST_FILE"

    # 실제 배포 스크립트 실행 (성공, 실패 로그 전부 기록)
    if bash "$DEPLOY_SCRIPT" >> "$LOG_FILE" 2>&1; then
      echo "$(date '+%F %T') deploy success" >> "$LOG_FILE"
    else
      echo "$(date '+%F %T') deploy failed" >> "$LOG_FILE"
    fi
  fi

  sleep 2
done