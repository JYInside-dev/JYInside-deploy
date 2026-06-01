#!/usr/bin/env bash

INTERVAL="${1:-1}"
OUT_FILE="${2:-docker-stats-$(date '+%Y%m%d-%H%M%S').csv}"

echo "time,name,cpu_percent,mem_percent,pids" > "$OUT_FILE"

echo "Docker stats 모니터링을 시작합니다."
echo "interval=${INTERVAL}s"
echo "output=$OUT_FILE"
echo "Ctrl+C 를 눌러 종료하세요"

while true; do
  NOW=$(date '+%Y-%m-%d %H:%M:%S')

  docker stats --no-stream \
    --format "{{.Name}},{{.CPUPerc}},{{.MemPerc}},{{.PIDs}}" \
  | while IFS=',' read -r NAME CPU MEM PIDS; do
      CPU=${CPU%\%}
      MEM=${MEM%\%}
      echo "$NOW,$NAME,$CPU,$MEM,$PIDS" >> "$OUT_FILE"
    done

  sleep "$INTERVAL"
done