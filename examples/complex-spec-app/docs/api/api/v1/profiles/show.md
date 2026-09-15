# Get Profile

`GET /api/v1/profile`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Authorization | `Bearer {{token}}` |
| Accept | `application/json` |

## cURL

```bash
curl --request GET \
  --url "http://localhost:3000/api/v1/profile" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `1` |
| `name` | string | yes | `"Ada Lovelace"` |
| `email` | string | yes | `"ada@example.com"` |
| `locale` | string | yes | `"en"` |

```json
{
  "id": 1,
  "name": "Ada Lovelace",
  "email": "ada@example.com",
  "locale": "en"
}
```

### 401 Unauthorized

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `error` | string | yes | `"Unauthorized"` |

```json
{
  "error": "Unauthorized"
}
```

---

Resource: [Profiles](index.md)
