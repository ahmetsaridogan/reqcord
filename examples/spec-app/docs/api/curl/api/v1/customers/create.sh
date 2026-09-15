#!/usr/bin/env bash
set -euo pipefail

# Create Customer
# POST /api/v1/customers
curl --request POST \
  --url "http://localhost:3000/api/v1/customers" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "customer": {
    "name": "Ada Lovelace",
    "email": "ada@example.com",
    "status": "active"
  }
}'
