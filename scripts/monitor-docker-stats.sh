#!/usr/bin/env bash

set -euo pipefail

INTERVAL="${1:-1}"
NAME_FILTER="${2:-test-server}"

BASE_DIR="/opt/deploy-repo/community-deploy/test-server"
LOG_DIR="$BASE_DIR/logs/k6-test"
START_TIME="$(date '+%Y%m%d-%H%M%S')"
TMP_FILE="$LOG_DIR/docker-stats-$START_TIME.tmp.csv"

mkdir -p "$LOG_DIR"

echo "time,name,cpu_percent,mem_percent,pids" > "$TMP_FILE"

print_summary() {
  local file="$1"

  echo
  echo "===== MAX CPU ====="
  awk -F',' '
  NR > 1 {
    name=$2
    cpu=$3
    gsub(/%/, "", cpu)

    if (cpu ~ /^[0-9.]+$/) {
      cpu_num = cpu + 0
      if (!(name in max_cpu) || cpu_num > max_cpu[name]) {
        max_cpu[name] = cpu_num
      }
    }
  }
  END {
    for (name in max_cpu) {
      printf "%-45s max_cpu=%.2f%%\n", name, max_cpu[name]
    }
  }
  ' "$file" | sort

  echo
  echo "===== MAX MEMORY ====="
  awk -F',' '
  NR > 1 {
    name=$2
    mem=$4
    gsub(/%/, "", mem)

    if (mem ~ /^[0-9.]+$/) {
      mem_num = mem + 0
      if (!(name in max_mem) || mem_num > max_mem[name]) {
        max_mem[name] = mem_num
      }
    }
  }
  END {
    for (name in max_mem) {
      printf "%-45s max_mem=%.2f%%\n", name, max_mem[name]
    }
  }
  ' "$file" | sort
}

finish() {
  echo
  echo "Docker stats monitoring stopped."

  read -rp "저장할 파일명 입력, 예: spike-500-stats.csv : " FINAL_NAME

  if [ -z "$FINAL_NAME" ]; then
    FINAL_NAME="docker-stats-$START_TIME.csv"
  fi

  # 확장자 없으면 .csv 자동 추가
  if [[ "$FINAL_NAME" != *.csv ]]; then
    FINAL_NAME="$FINAL_NAME.csv"
  fi

  # 경로 문자 방지
  FINAL_NAME="$(basename "$FINAL_NAME")"

  FINAL_FILE="$LOG_DIR/$FINAL_NAME"
  mv "$TMP_FILE" "$FINAL_FILE"

  echo "Saved: $FINAL_FILE"

  SUMMARY_FILE="${FINAL_FILE%.csv}-summary.txt"
  {
    echo "file=$FINAL_FILE"
    echo "interval=${INTERVAL}s"
    echo "name_filter=$NAME_FILTER"
    print_summary "$FINAL_FILE"
  } | tee "$SUMMARY_FILE"

  echo
  echo "Summary saved: $SUMMARY_FILE"
  exit 0
}

trap finish INT TERM

echo "Docker stats monitoring started."
echo "interval=${INTERVAL}s"
echo "name_filter=$NAME_FILTER"
echo "temp_file=$TMP_FILE"
echo "Press Ctrl+C to stop."

while true; do
  NOW="$(date '+%Y-%m-%d %H:%M:%S')"

  docker stats --no-stream \
    --format "{{.Name}},{{.CPUPerc}},{{.MemPerc}},{{.PIDs}}" \
  | while IFS=',' read -r NAME CPU MEM PIDS; do

      if [ "$NAME_FILTER" != "all" ] && [[ "$NAME" != *"$NAME_FILTER"* ]]; then
        continue
      fi

      CPU="${CPU%\%}"
      MEM="${MEM%\%}"

      echo "$NOW,$NAME,$CPU,$MEM,$PIDS" >> "$TMP_FILE"
    done

  sleep "$INTERVAL"
done