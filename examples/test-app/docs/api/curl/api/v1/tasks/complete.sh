#!/usr/bin/env bash
set -euo pipefail

# Complete Task
# POST /api/v1/tasks/:id/complete
curl --request POST \
  --url "http://localhost:3000/api/v1/tasks/1/complete" \
  --header "Accept: application/json"
