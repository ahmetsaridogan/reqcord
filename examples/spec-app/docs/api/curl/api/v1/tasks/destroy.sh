#!/usr/bin/env bash
set -euo pipefail

# Delete Task
# DELETE /api/v1/tasks/:id
curl --request DELETE \
  --url "http://localhost:3000/api/v1/tasks/3" \
  --header "Accept: application/json"
