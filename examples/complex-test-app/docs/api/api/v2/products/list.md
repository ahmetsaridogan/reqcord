# List Products

`GET /api/v2/products`

Namespace: `api/v2`

## Headers

| Header | Value |
| --- | --- |
| Accept | `application/json` |

## Query Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `cursor` | string | no | `"eyJpZCI6Mn0"` |

## cURL

```bash
curl --request GET \
  --url "http://localhost:3000/api/v2/products?cursor=eyJpZCI6Mn0" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `items[].id` | integer | yes | `4` |
| `items[].sku` | string | yes | `"MUG-002"` |
| `items[].name` | string | yes | `"Travel Mug"` |
| `items[].category` | string | yes | `"mugs"` \| `"tea"` |
| `items[].price_cents` | integer | yes | `3200` |
| `items[].tags[]` | string | yes | `"green"` \| `"insulated"` |
| `items[].price` | string | yes | `"32.00"` |
| `next_cursor` | null | string | yes | `"eyJpZCI6Mn0"` |

```json
{
  "items": [
    {
      "id": 3,
      "sku": "MUG-001",
      "name": "Stoneware Mug",
      "category": "mugs",
      "price_cents": 2400,
      "tags": [
        "ceramic"
      ],
      "price": "24.00"
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
      ],
      "price": "32.00"
    }
  ],
  "next_cursor": null
}
```

---

Resource: [Products](index.md)
