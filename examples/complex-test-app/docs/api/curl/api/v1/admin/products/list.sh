#!/usr/bin/env bash
set -euo pipefail

# List Products
# GET /api/v1/admin/products
curl --request GET \
  --url "http://localhost:3000/api/v1/admin/products" \
  --header "X-Api-Key: {{api_key}}" \
  --header "Accept: application/json"
