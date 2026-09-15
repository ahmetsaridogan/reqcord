#!/usr/bin/env bash
set -euo pipefail

# Login
# POST /api/v1/auth/login
curl --request POST \
  --url "http://localhost:3000/api/v1/auth/login" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data 'email=ada%40example.com&password=%7B%7Bpassword%7D%7D'
