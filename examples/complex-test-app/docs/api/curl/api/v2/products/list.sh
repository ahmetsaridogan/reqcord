#!/usr/bin/env bash
set -euo pipefail

# List Products
# GET /api/v2/products
curl --request GET \
  --url "http://localhost:3000/api/v2/products?cursor=eyJpZCI6Mn0" \
  --header "Accept: application/json"
