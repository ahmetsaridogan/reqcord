# Cancel Order

`POST /api/v1/orders/:id/cancel`

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
curl --request POST \
  --url "http://localhost:3000/api/v1/orders/1/cancel" \
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
| `status` | string | yes | `"cancelled"` |
| `currency` | string | yes | `"USD"` |
| `total_cents` | integer | yes | `2700` |

```json
{
  "id": 1,
  "user_id": 1,
  "status": "cancelled",
  "currency": "USD",
  "total_cents": 2700
}
```

### 409 Conflict

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `error` | string | yes | `"Shipped orders cannot be cancelled"` |

```json
{
  "error": "Shipped orders cannot be cancelled"
}
```

---

Resource: [Orders](index.md)
