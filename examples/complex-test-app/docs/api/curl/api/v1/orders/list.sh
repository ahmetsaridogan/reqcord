#!/usr/bin/env bash
set -euo pipefail

# List Orders
# GET /api/v1/orders
curl --request GET \
  --url "http://localhost:3000/api/v1/orders?status=pending" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
