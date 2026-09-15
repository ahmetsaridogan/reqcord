# Get Cart

`GET /api/v1/cart`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Authorization | `Bearer {{token}}` |
| Accept | `application/json` |

## cURL

```bash
curl --request GET \
  --url "http://localhost:3000/api/v1/cart" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `items[].sku` | string | yes | `"MUG-001"` |
| `items[].name` | string | yes | `"Stoneware Mug"` |
| `items[].quantity` | integer | yes | `1` |
| `items[].unit_price_cents` | integer | yes | `2400` |
| `total_cents` | integer | yes | `4800` |

```json
{
  "items": [
    {
      "sku": "TEA-001",
      "name": "Earl Grey",
      "quantity": 2,
      "unit_price_cents": 1200
    },
    {
      "sku": "MUG-001",
      "name": "Stoneware Mug",
      "quantity": 1,
      "unit_price_cents": 2400
    }
  ],
  "total_cents": 4800
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

Resource: [Carts](index.md)
