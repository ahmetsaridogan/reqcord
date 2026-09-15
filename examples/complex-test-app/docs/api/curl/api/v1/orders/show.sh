#!/usr/bin/env bash
set -euo pipefail

# Get Order
# GET /api/v1/orders/:id
curl --request GET \
  --url "http://localhost:3000/api/v1/orders/1" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
