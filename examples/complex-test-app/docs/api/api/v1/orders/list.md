# List Orders

`GET /api/v1/orders`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Authorization | `Bearer {{token}}` |
| Accept | `application/json` |

## Query Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `status` | string | no | `"pending"` \| `"shipped"` |

## cURL

```bash
curl --request GET \
  --url "http://localhost:3000/api/v1/orders?status=pending" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `[].id` | integer | yes | `1` |
| `[].user_id` | integer | yes | `1` |
| `[].status` | string | yes | `"pending"` \| `"shipped"` |
| `[].currency` | string | yes | `"USD"` |
| `[].total_cents` | integer | yes | `2700` |

```json
[
  {
    "id": 1,
    "user_id": 1,
    "status": "pending",
    "currency": "USD",
    "total_cents": 2700
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

Resource: [Orders](index.md)
