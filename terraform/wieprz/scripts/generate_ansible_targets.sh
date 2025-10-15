#!/usr/bin/env bash

terraform show -json 2>/dev/null | jq -r '
  .values.root_module.child_modules[]
  | select(.address | startswith("module.ansible_"))
  | .address
  | sub("module.ansible_"; "")
' 2>/dev/null

