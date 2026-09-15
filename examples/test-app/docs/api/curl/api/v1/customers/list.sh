#!/usr/bin/env bash
set -euo pipefail

# List Customers
# GET /api/v1/customers
curl --request GET \
  --url "http://localhost:3000/api/v1/customers?per_page=1" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
