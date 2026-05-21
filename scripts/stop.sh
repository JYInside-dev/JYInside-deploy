#!/usr/bin/env bash


echo ">>> 중지 스크립트 실행"

# blue or green 인자로 받기
TARGET=$1

if [ "$TARGET" != "blue" ] && [ "$TARGET" != "green" ]; then
    echo "오류: 'blue' 또는 'green'을 입력해주세요. (예: ./deploy.sh [blue or green])"
        exit 1
fi


DIR_PATH="/opt/deploy-repo/community-deploy/${TARGET}-server"
#DIR_PATH="/mnt/c/Users/najy1/cicd-project/${TARGET}-server"


echo ">>> ${TARGET}서버 중지를 시작합니다."


# 인프라 도커는 실제 서비스에서는 중지 안할거
docker compose -f "${DIR_PATH}/docker-compose-${TARGET}-infra.yml" down || { echo "❌ 인프라 도커 중지 실패!"; exit 1; }

# 프론트/백엔드 서버만 키고 끌거에요
docker compose -f "${DIR_PATH}/docker-compose-${TARGET}.yml" down || { echo "❌ 서버 도커 중지 실패!"; exit 1; }

echo ">>> ${TARGET}서버 종료 완료!"



