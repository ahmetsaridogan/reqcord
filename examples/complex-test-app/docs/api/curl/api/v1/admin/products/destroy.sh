#!/usr/bin/env bash
set -euo pipefail

# Delete Product
# DELETE /api/v1/admin/products/:id
curl --request DELETE \
  --url "http://localhost:3000/api/v1/admin/products/4" \
  --header "X-Api-Key: {{api_key}}" \
  --header "Accept: application/json"
