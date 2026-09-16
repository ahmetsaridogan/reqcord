#!/usr/bin/env bash
set -euo pipefail

# Checkout Cart
# POST /api/v1/cart/checkout
curl --request POST \
  --url "http://localhost:3000/api/v1/cart/checkout" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "payment_method": "card"
}'
