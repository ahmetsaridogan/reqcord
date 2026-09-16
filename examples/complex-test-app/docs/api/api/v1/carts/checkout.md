# Checkout Cart

`POST /api/v1/cart/checkout`

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
| `payment_method` | string | yes | `"bank_transfer"` \| `"card"` |

## Example Request

```json
{
  "payment_method": "bank_transfer"
}
```

## cURL

```bash
curl --request POST \
  --url "http://localhost:3000/api/v1/cart/checkout" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "payment_method": "bank_transfer"
}'
```

## Responses

### 201 Created

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `5` |
| `status` | string | yes | `"pending"` |
| `payment_method` | string | yes | `"bank_transfer"` \| `"card"` |
| `total_cents` | integer | yes | `4800` |
| `line_items[].sku` | string | yes | `"MUG-001"` |
| `line_items[].name` | string | yes | `"Stoneware Mug"` |
| `line_items[].quantity` | integer | yes | `1` |
| `line_items[].unit_price_cents` | integer | yes | `2400` |

```json
{
  "id": 5,
  "status": "pending",
  "payment_method": "bank_transfer",
  "total_cents": 4800,
  "line_items": [
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
  ]
}
```

### 422 Unprocessable Content

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `errors.payment_method[]` | string | yes | `"is not included in the list"` |

```json
{
  "errors": {
    "payment_method": [
      "is not included in the list"
    ]
  }
}
```

---

Resource: [Carts](index.md)
