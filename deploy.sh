#!/usr/bin/env bash

echo ">>> 배포 스크립트를 실행합니다."

# be-blue가 맞는지는 확인해봐야알듯.
EXIST_BLUE=$(docker container ls | grep backend-blue)


# if EXIST_BLUE.length == 0
if [ -z "$EXIST_BLUE" ]; then
    echo ">>> 현재 Green이 배포중입니다. Blue로 갈아끼울게요";
    TARGET="blue"
    CURRENT="green"
else
    echo ">>> 현재 Blue가 배포중입니다. Green으로 갈아끼울게요";
    TARGET="green"
    CURRENT="blue"
fi


# Docker compose의 서비스들 이미지 링크에서 pull
docker compose pull backend-${TARGET} frontend-${TARGET}
# 실행을 대기하고 있던 Green이미지들 실행 ㄱㄱ
docker compose --profile standBy up -d backend-${TARGET} frontend-${TARGET}

echo ">>> ${TARGET}컨테이너가 실행 될 때 까지 잠시 대기합니다."
sleep 15

# nginx설정파일에서 서비스의 이름 문자열 교체
sed -i "s/backend-${CURRENT}/backend-${TARGET}/g" ./nginx/nginx.conf
sed -i "s/frontend-${CURRENT}/frontend-${TARGET}/g" ./nginx/nginx.conf


# nginx 서비스 다시 리로드
docker compose exec nginx nginx -s reload
echo  ">>> nginx 트래픽이 ${TARGET}으로 변경되었습니다. 서비스 다시 시작하는 중"

docker compose stop backend-${CURRENT} frontend-${CURRENT}
echo ">>> 기존에 사용하던 구버전 ${CURRENT} 서버 내림 새버전 배포 완료!"


