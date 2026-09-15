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
| `order.line_items[].sku` | string | yes | `"MUG-001"` |
| `order.line_items[].quantity` | integer | yes | `1` |
| `order.shipping_address.line1` | string | yes | `"1 Analytical Engine Way"` |
| `order.shipping_address.city` | string | yes | `"London"` |
| `order.shipping_address.country` | string | yes | `"GB"` \| `"IT"` |

## Example Request

```json
{
  "order": {
    "line_items": [
      {
        "sku": "TEA-001",
        "quantity": 2
      },
      {
        "sku": "MUG-001",
        "quantity": 1
      }
    ],
    "shipping_address": {
      "line1": "1 Analytical Engine Way",
      "city": "London",
      "country": "GB"
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
        "sku": "TEA-001",
        "quantity": 2
      },
      {
        "sku": "MUG-001",
        "quantity": 1
      }
    ],
    "shipping_address": {
      "line1": "1 Analytical Engine Way",
      "city": "London",
      "country": "GB"
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
| `total_cents` | integer | yes | `4800` |
| `line_items[].sku` | string | yes | `"MUG-001"` |
| `line_items[].name` | string | yes | `"Stoneware Mug"` |
| `line_items[].quantity` | integer | yes | `1` |
| `line_items[].unit_price_cents` | integer | yes | `2400` |
| `line_items[].subtotal_cents` | integer | yes | `2400` |
| `shipping_address.line1` | string | yes | `"1 Analytical Engine Way"` |
| `shipping_address.city` | string | yes | `"London"` |
| `shipping_address.country` | string | yes | `"GB"` \| `"IT"` |

```json
{
  "id": 4,
  "status": "pending",
  "currency": "USD",
  "total_cents": 4800,
  "line_items": [
    {
      "sku": "TEA-001",
      "name": "Earl Grey",
      "quantity": 2,
      "unit_price_cents": 1200,
      "subtotal_cents": 2400
    },
    {
      "sku": "MUG-001",
      "name": "Stoneware Mug",
      "quantity": 1,
      "unit_price_cents": 2400,
      "subtotal_cents": 2400
    }
  ],
  "shipping_address": {
    "line1": "1 Analytical Engine Way",
    "city": "London",
    "country": "GB"
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
