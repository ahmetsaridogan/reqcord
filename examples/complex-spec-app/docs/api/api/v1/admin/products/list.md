# List Products

`GET /api/v1/admin/products`

Namespace: `api/v1/admin`

## Headers

| Header | Value |
| --- | --- |
| X-Api-Key | `{{api_key}}` |
| Accept | `application/json` |

## cURL

```bash
curl --request GET \
  --url "http://localhost:3000/api/v1/admin/products" \
  --header "X-Api-Key: {{api_key}}" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `[].id` | integer | yes | `4` |
| `[].sku` | string | yes | `"MUG-002"` |
| `[].name` | string | yes | `"Travel Mug"` |
| `[].category` | string | yes | `"mugs"` |
| `[].price_cents` | integer | yes | `3200` |
| `[].cost_cents` | integer | yes | `1400` |
| `[].tags[]` | string | yes | `"insulated"` |

```json
[
  {
    "id": 1,
    "sku": "TEA-001",
    "name": "Earl Grey",
    "category": "tea",
    "price_cents": 1200,
    "cost_cents": 500,
    "tags": [
      "black",
      "bergamot"
    ]
  },
  {
    "id": 2,
    "sku": "TEA-002",
    "name": "Sencha",
    "category": "tea",
    "price_cents": 1500,
    "cost_cents": 700,
    "tags": [
      "green"
    ]
  },
  {
    "id": 3,
    "sku": "MUG-001",
    "name": "Stoneware Mug",
    "category": "mugs",
    "price_cents": 2400,
    "cost_cents": 900,
    "tags": [
      "ceramic"
    ]
  },
  {
    "id": 4,
    "sku": "MUG-002",
    "name": "Travel Mug",
    "category": "mugs",
    "price_cents": 3200,
    "cost_cents": 1400,
    "tags": [
      "steel",
      "insulated"
    ]
  }
]
```

### 401 Unauthorized

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `error` | string | yes | `"API key required"` |

```json
{
  "error": "API key required"
}
```

---

Resource: [Products](index.md)
