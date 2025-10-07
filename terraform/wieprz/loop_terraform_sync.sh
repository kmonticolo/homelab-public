#!/bin/bash

cd /root/homelab-public/terraform/wieprz || exit 1

while true; do
    echo "=== \$(date '+%Y-%m-%d %H:%M:%S') ===" >> terraform_sync.log
    pytest -s test_terraform_sync.py >> terraform_sync.log 2>&1
    sleep 3
done
