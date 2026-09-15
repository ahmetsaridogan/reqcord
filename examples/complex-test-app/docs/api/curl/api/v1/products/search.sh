#!/usr/bin/env bash
set -euo pipefail

# Search Products
# GET /api/v1/products/search
curl --request GET \
  --url "http://localhost:3000/api/v1/products/search?q=mug" \
  --header "Accept: application/json"
