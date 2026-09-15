# Get Customer

`GET /api/v1/customers/:id`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Authorization | `Bearer {{token}}` |
| Accept | `application/json` |

## Path Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | string | yes | `"1"` |

## cURL

```bash
curl --request GET \
  --url "http://localhost:3000/api/v1/customers/1" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `1` |
| `name` | string | yes | `"John Doe"` |
| `email` | string | yes | `"john@example.com"` |

```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com"
}
```

### 404 Not Found

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `error` | string | yes | `"Not Found"` |

```json
{
  "error": "Not Found"
}
```

---

Resource: [Customers](index.md)
