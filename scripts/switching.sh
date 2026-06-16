#!/usr/bin/env bash

echo ">>> 서버 스위칭 스크립트를 실행합니다."

TARGET=$1

if [ "$TARGET" != "blue" ] && [ "$TARGET" != "green" ]; then
    echo "오류: 'blue' 또는 'green'를 입력해주세요. (예: ./switching.sh [blue or green])"
            exit 1
fi

if [ "$TARGET" = "blue" ]; then
    CURRENT="green"
else
    CURRENT="blue"
fi


#DIR_PATH="/mnt/c/Users/najy1/cicd-project/service-server"
DIR_PATH="/opt/deploy-repo/community-deploy/service-server"
NGINX_CONF_PATH="${DIR_PATH}/nginx/nginx.conf"

# 실제 띄워지는 nginx 컨테이너 이름.
NGINX_CONTAINER="service-server-nginx-1"

echo ">>> [$TARGET] 환경으로 트래픽 전환을 시작합니다."

echo ">>> 1. ${TARGET} 백엔드/프론트엔드 컨테이너 가동"
docker compose -f "${DIR_PATH}/docker-compose-service.yml" up -d backend-${TARGET} frontend-${TARGET} || { echo "${TARGET}서버 컨테이너 기동 중 오류발생"; exit 1; }


echo ">>> 2. ${TARGET} 백엔드 서버 부팅 확인 중"
for i in {1..30} ; do
    RESPONSE=$(docker exec backend-${TARGET} curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/health || echo "000")

    if [ "$RESPONSE" -eq 200 ]; then
        echo "백엔드 서버 부팅 완료! (응답코드: 200)"
        break
    fi

    if [ "$i" -eq 30 ]; then
        echo "45초 초과: 백엔드 서버가 켜지지 않았습니다. 배포를 중단합니다."
        # 배포 실패 시 켜려던 타겟 컨테이너를 다시 내림 (롤백)
        docker compose -f "${DIR_PATH}/docker-compose-service.yml" stop backend-${TARGET} frontend-${TARGET}
        exit 1
    fi

    echo "대기 중... ($i/30)"
    sleep 3
done

# Nginx.conf 파일 포트포워딩 설정 치환

echo ">>> 3. Nginx 라우팅 타겟 변경 (${CURRENT} ➔ ${TARGET})"
# nginx.conf 파일 내부의 글자를 찾아서 바꿉니다.
sed -i "s/backend-${CURRENT}/backend-${TARGET}/g" $NGINX_CONF_PATH  || { echo "nginx 라우팅 타겟 변경중 오류 발생 "; exit 1; }
sed -i "s/frontend-${CURRENT}/frontend-${TARGET}/g" $NGINX_CONF_PATH || { echo "nginx 라우팅 타겟 변경중 오류 발생 "; exit 1; }


# nginx 재시작
echo ">>> 4. Nginx 재시작"
docker exec $NGINX_CONTAINER nginx -s reload || { echo "nginx 재시작 중 오류 발생 "; exit 1; }


echo ">>> 5. 구버전(${CURRENT}) 컨테이너 종료"
bash "/opt/deploy-repo/community-deploy/scripts/stop.sh" "${CURRENT}" || { echo "구버전 서버 중지 스크립트 오류"; exit 1; }
#bash "/mnt/c/Users/najy1/cicd-project/scripts/stop.sh" "${CURRENT}" || { echo "구버전 서버 중지 스크립트 오류"; exit 1; }
echo "무중단 스위칭 완료! 현재 활성화된 서버: [${TARGET}]"


# ========================================================================================


