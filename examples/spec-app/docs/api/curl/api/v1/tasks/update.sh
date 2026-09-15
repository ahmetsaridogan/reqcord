#!/usr/bin/env bash
set -euo pipefail

# Update Task
# PATCH /api/v1/tasks/:id
curl --request PATCH \
  --url "http://localhost:3000/api/v1/tasks/1" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "task": {
    "title": "Write better docs"
  }
}'
