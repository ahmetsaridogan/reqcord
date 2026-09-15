#!/usr/bin/env bash
set -euo pipefail

# Get Customer
# GET /api/v1/customers/:id
curl --request GET \
  --url "http://localhost:3000/api/v1/customers/1" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
