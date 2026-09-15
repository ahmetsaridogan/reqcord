# List Users

`GET /api/v1/users`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Authorization | `Bearer {{token}}` |
| Accept | `application/json` |

## Query Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `per_page` | integer | yes | `1` |

## cURL

```bash
curl --request GET \
  --url "http://localhost:3000/api/v1/users?per_page=1" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `[].id` | integer | yes | `1` |
| `[].name` | string | yes | `"John Doe"` |
| `[].email` | string | yes | `"john@example.com"` |

```json
[
  {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
]
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

Resource: [Users](index.md)
