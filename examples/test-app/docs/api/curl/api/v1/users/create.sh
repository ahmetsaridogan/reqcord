#!/usr/bin/env bash
set -euo pipefail

# Create User
# POST /api/v1/users
curl --request POST \
  --url "http://localhost:3000/api/v1/users" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "user": {
    "name": "Ada Lovelace",
    "email": "ada@example.com",
    "status": "active"
  }
}'
