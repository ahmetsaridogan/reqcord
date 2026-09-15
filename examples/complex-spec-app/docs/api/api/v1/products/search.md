# Search Products

`GET /api/v1/products/search`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Accept | `application/json` |

## Query Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `q` | string | yes | `"mug"` |

## cURL

```bash
curl --request GET \
  --url "http://localhost:3000/api/v1/products/search?q=mug" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `query` | string | yes | `"mug"` |
| `results[].id` | integer | yes | `4` |
| `results[].sku` | string | yes | `"MUG-002"` |
| `results[].name` | string | yes | `"Travel Mug"` |
| `results[].category` | string | yes | `"mugs"` |
| `results[].price_cents` | integer | yes | `3200` |
| `results[].tags[]` | string | yes | `"insulated"` |

```json
{
  "query": "mug",
  "results": [
    {
      "id": 3,
      "sku": "MUG-001",
      "name": "Stoneware Mug",
      "category": "mugs",
      "price_cents": 2400,
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
      "tags": [
        "steel",
        "insulated"
      ]
    }
  ]
}
```

### 400 Bad Request

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `error` | string | yes | `"q is required"` |

```json
{
  "error": "q is required"
}
```

---

Resource: [Products](index.md)
