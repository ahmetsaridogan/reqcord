#!/usr/bin/env bash
set -euo pipefail

# List Notes
# GET /api/v1/orders/:order_id/notes
curl --request GET \
  --url "http://localhost:3000/api/v1/orders/1/notes" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
