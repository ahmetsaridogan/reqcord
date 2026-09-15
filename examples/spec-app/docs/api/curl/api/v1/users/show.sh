#!/usr/bin/env bash
set -euo pipefail

# Get User
# GET /api/v1/users/:id
curl --request GET \
  --url "http://localhost:3000/api/v1/users/1" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
