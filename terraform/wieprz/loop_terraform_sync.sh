#!/bin/bash

cd /root/homelab-public/terraform/wieprz || exit 1

current_hour=$(date +%H)
if [ "$current_hour" -ge 17 ] && [ "$current_hour" -lt 20 ]; then
  exit 0
else
while true; do
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') ===" >> terraform_sync.log
    pytest -s test_terraform_sync.py --delete-orphans >> terraform_sync.log 2>&1
    sleep 60
done
fi
