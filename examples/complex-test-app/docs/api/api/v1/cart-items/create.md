# Create Cart Item

`POST /api/v1/cart/items`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Authorization | `Bearer {{token}}` |
| Content-Type | `application/json` |
| Accept | `application/json` |

## Body Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `item.sku` | string | yes | `"TEA-002"` |
| `item.quantity` | integer | yes | `3` |

## Example Request

```json
{
  "item": {
    "sku": "TEA-002",
    "quantity": 3
  }
}
```

## cURL

```bash
curl --request POST \
  --url "http://localhost:3000/api/v1/cart/items" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "item": {
    "sku": "TEA-002",
    "quantity": 3
  }
}'
```

## Responses

### 201 Created

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `sku` | string | yes | `"TEA-002"` |
| `name` | string | yes | `"Sencha"` |
| `quantity` | integer | yes | `3` |
| `unit_price_cents` | integer | yes | `1500` |

```json
{
  "sku": "TEA-002",
  "name": "Sencha",
  "quantity": 3,
  "unit_price_cents": 1500
}
```

### 422 Unprocessable Content

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `errors.sku[]` | string | yes | `"TEA-999 is not a known product"` |

```json
{
  "errors": {
    "sku": [
      "TEA-999 is not a known product"
    ]
  }
}
```

---

Resource: [Cart Items](index.md)
