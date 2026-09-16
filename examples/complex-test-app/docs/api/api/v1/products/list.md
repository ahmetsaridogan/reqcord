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
  --url "http://localhost:3000/api/v1/products?filter%5Bcategory%5D=mugs" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `data[].id` | integer | yes | `4` |
| `data[].sku` | string | yes | `"MUG-002"` |
| `data[].name` | string | yes | `"Travel Mug"` |
| `data[].category` | string | yes | `"mugs"` \| `"tea"` |
| `data[].price_cents` | integer | yes | `3200` |
| `data[].tags[]` | string | yes | `"ceramic"` \| `"green"` \| `"insulated"` |
| `meta.page` | integer | yes | `1` |
| `meta.per_page` | integer | yes | `2` |
| `meta.total` | integer | yes | `2` |

```json
{
  "data": [
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
  ],
  "meta": {
    "page": 1,
    "per_page": 2,
    "total": 2
  }
}
```

---

Resource: [Products](index.md)
