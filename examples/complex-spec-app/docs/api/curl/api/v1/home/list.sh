#!/usr/bin/env bash
set -euo pipefail

# Home
# GET /api/v1
curl --request GET \
  --url "http://localhost:3000/api/v1" \
  --header "Accept: application/json"
