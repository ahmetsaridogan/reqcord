#!/usr/bin/env bash
set -euo pipefail

# List Orders
# GET /api/v1/orders
curl --request GET \
  --url "http://localhost:3000/api/v1/orders" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
