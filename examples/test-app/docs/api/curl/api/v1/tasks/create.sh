#!/usr/bin/env bash
set -euo pipefail

# Create Task
# POST /api/v1/tasks
curl --request POST \
  --url "http://localhost:3000/api/v1/tasks" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "task": {
    "title": "Water the plants",
    "priority": "low"
  }
}'
