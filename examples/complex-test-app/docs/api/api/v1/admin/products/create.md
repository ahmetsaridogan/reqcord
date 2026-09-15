# Create Product

`POST /api/v1/admin/products`

Namespace: `api/v1/admin`

## Headers

| Header | Value |
| --- | --- |
| X-Api-Key | `{{api_key}}` |
| Content-Type | `application/json` |
| Accept | `application/json` |

## Body Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `product.sku` | string | yes | `"TEA-003"` |
| `product.name` | string | yes | `"Jasmine"` |
| `product.category` | string | yes | `"tea"` |
| `product.price_cents` | integer | yes | `1400` |

## Example Request

```json
{
  "product": {
    "sku": "TEA-003",
    "name": "Jasmine",
    "category": "tea",
    "price_cents": 1400
  }
}
```

## cURL

```bash
curl --request POST \
  --url "http://localhost:3000/api/v1/admin/products" \
  --header "X-Api-Key: {{api_key}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "product": {
    "sku": "TEA-003",
    "name": "Jasmine",
    "category": "tea",
    "price_cents": 1400
  }
}'
```

## Responses

### 201 Created

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `5` |
| `cost_cents` | integer | yes | `0` |
| `tags` | array | yes | - |
| `sku` | string | yes | `"TEA-003"` |
| `name` | string | yes | `"Jasmine"` |
| `category` | string | yes | `"tea"` |
| `price_cents` | integer | yes | `1400` |

```json
{
  "id": 5,
  "cost_cents": 0,
  "tags": [],
  "sku": "TEA-003",
  "name": "Jasmine",
  "category": "tea",
  "price_cents": 1400
}
```

### 409 Conflict

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `error` | string | yes | `"sku TEA-001 already exists"` |

```json
{
  "error": "sku TEA-001 already exists"
}
```

### 422 Unprocessable Content

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `errors.sku[]` | string | yes | `"can't be blank"` |

```json
{
  "errors": {
    "sku": [
      "can't be blank"
    ]
  }
}
```

---

Resource: [Products](index.md)
