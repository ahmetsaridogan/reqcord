#!/usr/bin/env bash
set -euo pipefail

# Get Cart
# GET /api/v1/cart
curl --request GET \
  --url "http://localhost:3000/api/v1/cart" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
