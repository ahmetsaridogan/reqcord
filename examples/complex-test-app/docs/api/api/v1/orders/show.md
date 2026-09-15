# Get Order

`GET /api/v1/orders/:id`

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
  --url "http://localhost:3000/api/v1/orders/1" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `1` |
| `user_id` | integer | yes | `1` |
| `status` | string | yes | `"pending"` |
| `currency` | string | yes | `"USD"` |
| `total_cents` | integer | yes | `2700` |

```json
{
  "id": 1,
  "user_id": 1,
  "status": "pending",
  "currency": "USD",
  "total_cents": 2700
}
```

### 403 Forbidden

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `error` | string | yes | `"Forbidden"` |

```json
{
  "error": "Forbidden"
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

Resource: [Orders](index.md)
