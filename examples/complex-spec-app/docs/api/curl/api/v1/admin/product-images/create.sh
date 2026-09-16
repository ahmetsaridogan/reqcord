#!/usr/bin/env bash
set -euo pipefail

# Create Product Image
# POST /api/v1/admin/products/:product_id/image
curl --request POST \
  --url "http://localhost:3000/api/v1/admin/products/1/image" \
  --header "X-Api-Key: {{api_key}}" \
  --form 'image=@label.png;type=image/png' \
  --form 'alt=Stoneware mug on a table'
