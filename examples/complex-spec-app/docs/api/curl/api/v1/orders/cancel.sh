#!/usr/bin/env bash
set -euo pipefail

# Cancel Order
# POST /api/v1/orders/:id/cancel
curl --request POST \
  --url "http://localhost:3000/api/v1/orders/1/cancel" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
