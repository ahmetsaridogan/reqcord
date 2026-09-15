#!/usr/bin/env bash
set -euo pipefail

# Get Profile
# GET /api/v1/profile
curl --request GET \
  --url "http://localhost:3000/api/v1/profile" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
