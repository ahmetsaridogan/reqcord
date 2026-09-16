# List Products

`GET /api/v1/products`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Accept | `application/json` |

## Query Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `filter.category` | string | no | `"mugs"` \| `"tea"` |
| `sort` | string | no | `"price_asc"` \| `"price_desc"` |
| `page` | integer | no | `2` |
| `per_page` | integer | no | `2` |

## cURL

```bash
curl --request GET \
  --url "http://localhost:3000/api/v1/products" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `data[].id` | integer | yes | `2` |
| `data[].sku` | string | yes | `"TEA-002"` |
| `data[].name` | string | yes | `"Sencha"` |
| `data[].category` | string | yes | `"mugs"` \| `"tea"` |
| `data[].price_cents` | integer | yes | `1500` |
| `data[].tags[]` | string | yes | `"ceramic"` \| `"green"` \| `"insulated"` |
| `meta.page` | integer | yes | `1` |
| `meta.per_page` | integer | yes | `2` |
| `meta.total` | integer | yes | `4` |

```json
{
  "data": [
    {
      "id": 1,
      "sku": "TEA-001",
      "name": "Earl Grey",
      "category": "tea",
      "price_cents": 1200,
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
      "tags": [
        "green"
      ]
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 2,
    "total": 4
  }
}
```

---

Resource: [Products](index.md)
