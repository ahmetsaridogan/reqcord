#!/usr/bin/env bash
set -euo pipefail

# List Products
# GET /api/v1/products
curl --request GET \
  --url "http://localhost:3000/api/v1/products?filter%5Bcategory%5D=tea" \
  --header "Accept: application/json"
