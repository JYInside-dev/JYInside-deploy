#!/usr/bin/env bash

echo ">>> 서버 배포 스크립트를 실행합니다."

# service, test 인자로 받음
TARGET=$1

if [ "$TARGET" != "service" ] && [ "$TARGET" != "test" ]; then
    echo "오류: 'service' 또는 'test'를 입력해주세요. (예: ./deploy.sh [service or test])"
        exit 1
fi


DIR_PATH="/opt/deploy-repo/community-deploy/${TARGET}-server"
#DIR_PATH="/mnt/c/Users/najy1/cicd-project/${TARGET}-server"


# 테스트 서버 분기
if [ "$TARGET" = "test" ]; then
    echo ">>> ${TARGET}서버 가동 시작합니다."
    docker compose -f "${DIR_PATH}/docker-compose-${TARGET}-infra.yml" up -d || { echo "❌ 인프라 도커 실행 실패!"; exit 1; }

    # 테스트서버는 항상 최신 이미지 pull 해서 사용
    docker compose -f "${DIR_PATH}/docker-compose-${TARGET}.yml" pull backend-test frontend-test

    docker compose -f "${DIR_PATH}/docker-compose-${TARGET}.yml" up -d || { echo "❌ 서버 도커 실행 실패!"; exit 1; }

    echo "Test 서버 실행 완료!"
    exit 0
fi



# 서비스 서버 분기
# nginx 설정파일에서 마지막으로 서비스됐던 서버가 블루인지 그린인지 판별
NGINX_CONF="${DIR_PATH}/nginx/nginx.conf"

LAST_TARGET=$(grep -oE 'backend-(blue|green)' "$NGINX_CONF" | head -1 | cut -d'-' -f2)
echo ">>> 마지막으로 실행했던 서비스서버는 [$LAST_TARGET] 입니다. 해당 서버를 가동합니다."

#인프라 먼저 기동
echo ">>> 1. 공유 인프라 컨테이너 가동"
docker compose -f "${DIR_PATH}/docker-compose-${TARGET}-infra.yml" up -d || { echo "❌ 인프라 도커 실행 실패!"; exit 1; }


echo ">>> 2. ${LAST_TARGET}서버 컨테이너 가동"
docker compose -f "${DIR_PATH}/docker-compose-${TARGET}.yml" up -d backend-${LAST_TARGET} frontend-${LAST_TARGET}

echo ">>> ${LAST_TARGET}서버 실행 완료! "

# 가비지 컨테이너들 회수
docker image prune -f





