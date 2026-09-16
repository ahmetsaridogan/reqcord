#!/usr/bin/env bash
set -euo pipefail

# List Tasks
# GET /api/v1/tasks
curl --request GET \
  --url "http://localhost:3000/api/v1/tasks?status=open" \
  --header "Accept: application/json"
