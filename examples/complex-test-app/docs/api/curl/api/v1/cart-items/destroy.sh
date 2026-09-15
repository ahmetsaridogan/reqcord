#!/usr/bin/env bash
set -euo pipefail

# Delete Cart Item
# DELETE /api/v1/cart/items/:sku
curl --request DELETE \
  --url "http://localhost:3000/api/v1/cart/items/TEA-001" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
