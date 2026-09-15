#!/usr/bin/env bash
set -euo pipefail

# Get Task
# GET /api/v1/tasks/:id
curl --request GET \
  --url "http://localhost:3000/api/v1/tasks/1" \
  --header "Accept: application/json"
