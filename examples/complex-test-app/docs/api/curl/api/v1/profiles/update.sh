#!/usr/bin/env bash
set -euo pipefail

# Update Profile
# PATCH /api/v1/profile
curl --request PATCH \
  --url "http://localhost:3000/api/v1/profile" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "profile": {
    "name": "Ada L.",
    "locale": "tr"
  }
}'
