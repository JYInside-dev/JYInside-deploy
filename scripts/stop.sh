#!/usr/bin/env bash

echo ">>> 중지 스크립트 실행"
# service or test 인자로 받기
TARGET=$1

if [ "${TARGET}" != "service" ] && [ "${TARGET}" != "test" ] && [ "${TARGET}" != "blue" ] && [ "${TARGET}" != "green" ]; then
    echo "오류: 잘못된 인자입니다."
    echo ">>> Test 서버 종료: ./stop.sh test "
    echo ">>> Service 서버 전체 종료: ./stop.sh service "
    echo ">>> Blue/Green 서버 선택 종료: ./stop.sh blue/green "
        exit 1
fi


# 테스트 서버의 경우: 인프라, 서비스 전부 down
if [ "${TARGET}" = "test" ]; then
    DIR_PATH="/mnt/c/Users/najy1/cicd-project/test-server"
    #DIR_PATH="/opt/deploy-repo/community-deploy/test-server"
    echo ">>> [test] 서버 및 인프라 중지를 시작합니다."

    docker compose -f "${DIR_PATH}/docker-compose-test.yml" down || { echo "❌ 테스트 서버 중지 실패!"; exit 1; }
    docker compose -f "${DIR_PATH}/docker-compose-test-infra.yml" down || { echo "❌ 테스트 서버 인프라 중지 실패!"; exit 1; }

    echo "✅ Test 서버 및 인프라 종료 완료!"
    exit 0
fi



# 실제 서비스 서버 분기점
DIR_PATH="/opt/deploy-repo/community-deploy/service-server"
#DIR_PATH="/mnt/c/Users/najy1/cicd-project/service-server"



# 서비스 blue/green 전체 종료 & 인프라 유지
if [ "${TARGET}" = "service" ]; then
    echo ">>> [service] 앱 서버 전체 중지를 시작합니다."

    # Nginx를 파싱할 필요 없이, service compose 전체를 down 하면 켜져있는 blue/green이 모두 안전하게 정리됩니다.
    docker compose -f "${DIR_PATH}/docker-compose-service.yml" --profile standBy down ||  { echo "❌ 서비스 서버 중지 실패!"; exit 1; }

    echo "✅ Service 앱 서버 전체 종료 완료!"
    exit 0
fi


# 스위칭 후 구버전 단일 중지 (./stop.sh blue 또는 ./stop.sh green)
if [ "${TARGET}" = "blue" ] || [ "$TARGET" = "green" ]; then
    echo ">>> [${TARGET}] 구버전 앱 컨테이너만 선택적으로 중지합니다."

    # 여기서 down을 쓰면 활성화된 서버의 네트워크까지 날아갈 수 있으므로, 해당 컨테이너만 정확히 찝어서 'stop' 시킵니다.
    docker compose -f "${DIR_PATH}/docker-compose-service.yml" stop backend-${TARGET} frontend-${TARGET} || { echo "❌ ${TARGET}서버 중지 실패!"; exit 1; }

    echo "✅ ${TARGET} 컨테이너 종료 완료!"
    exit 0
fi



