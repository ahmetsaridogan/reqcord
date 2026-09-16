# Create Order

`POST /api/v1/orders`

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
| `order.line_items[].sku` | string | yes | `"MUG-002"` |
| `order.line_items[].quantity` | integer | yes | `1` |
| `order.shipping_address.line1` | string | yes | `"Piazza"` |
| `order.shipping_address.city` | string | yes | `"Rome"` |
| `order.shipping_address.country` | string | yes | `"GB"` \| `"IT"` |

## Example Request

```json
{
  "order": {
    "line_items": [
      {
        "sku": "MUG-002",
        "quantity": 1
      }
    ],
    "shipping_address": {
      "line1": "Piazza",
      "city": "Rome",
      "country": "IT"
    }
  }
}
```

## cURL

```bash
curl --request POST \
  --url "http://localhost:3000/api/v1/orders" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "order": {
    "line_items": [
      {
        "sku": "MUG-002",
        "quantity": 1
      }
    ],
    "shipping_address": {
      "line1": "Piazza",
      "city": "Rome",
      "country": "IT"
    }
  }
}'
```

## Responses

### 201 Created

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `4` |
| `status` | string | yes | `"pending"` |
| `currency` | string | yes | `"USD"` |
| `total_cents` | integer | yes | `3200` |
| `line_items[].sku` | string | yes | `"MUG-002"` |
| `line_items[].name` | string | yes | `"Travel Mug"` |
| `line_items[].quantity` | integer | yes | `1` |
| `line_items[].unit_price_cents` | integer | yes | `3200` |
| `line_items[].subtotal_cents` | integer | yes | `3200` |
| `shipping_address.line1` | string | yes | `"Piazza"` |
| `shipping_address.city` | string | yes | `"Rome"` |
| `shipping_address.country` | string | yes | `"GB"` \| `"IT"` |

```json
{
  "id": 4,
  "status": "pending",
  "currency": "USD",
  "total_cents": 3200,
  "line_items": [
    {
      "sku": "MUG-002",
      "name": "Travel Mug",
      "quantity": 1,
      "unit_price_cents": 3200,
      "subtotal_cents": 3200
    }
  ],
  "shipping_address": {
    "line1": "Piazza",
    "city": "Rome",
    "country": "IT"
  }
}
```

### 422 Unprocessable Content

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `errors.sku[]` | string | no | `"TEA-999 is not a known product"` |
| `errors.line_items[]` | string | no | `"can't be blank"` |

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

Resource: [Orders](index.md)
