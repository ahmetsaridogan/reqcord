#!/usr/bin/env bash
set -euo pipefail

# Delete Order
# DELETE /api/v1/orders/:id
curl --request DELETE \
  --url "http://localhost:3000/api/v1/orders/1" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
