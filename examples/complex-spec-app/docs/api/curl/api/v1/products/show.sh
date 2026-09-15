#!/usr/bin/env bash
set -euo pipefail

# Get Product
# GET /api/v1/products/:id
curl --request GET \
  --url "http://localhost:3000/api/v1/products/3" \
  --header "Accept: application/json"
