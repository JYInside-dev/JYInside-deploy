# 1. 공식 베이스 이미지 사용
FROM fluent/fluentd:v1.19-1

# 2. 플러그인을 설치하기 위해 최고 관리자(root) 권한 획득
USER root

# 3. 카프카 연동 플러그인 설치 (Ruby의 패키지 매니저인 gem 사용)
RUN ["gem", "install", "fluent-plugin-kafka", "--no-document"]