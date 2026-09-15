#!/usr/bin/env bash
set -euo pipefail

# List Users
# GET /api/v1/users
curl --request GET \
  --url "http://localhost:3000/api/v1/users?per_page=1" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
