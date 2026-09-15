# Login

`POST /api/v1/auth/login`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Content-Type | `application/x-www-form-urlencoded` |

## Body Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `email` | string | yes | `"ada@example.com"` |
| `password` | string | yes | `"{{password}}"` |

## Example Request

Sent as `application/x-www-form-urlencoded`; the cURL below carries it in that encoding.

```json
{
  "email": "ada@example.com",
  "password": "{{password}}"
}
```

## cURL

```bash
curl --request POST \
  --url "http://localhost:3000/api/v1/auth/login" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data 'email=ada%40example.com&password=%7B%7Bpassword%7D%7D'
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `token` | string | yes | `"{{token}}"` |
| `token_type` | string | yes | `"Bearer"` |
| `expires_in` | integer | yes | `3600` |

```json
{
  "token": "{{token}}",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### 401 Unauthorized

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `error` | string | yes | `"Invalid email or password"` |

```json
{
  "error": "Invalid email or password"
}
```

---

Resource: [Auth](index.md)
