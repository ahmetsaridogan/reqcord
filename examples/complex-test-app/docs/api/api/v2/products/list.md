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
  --url "http://localhost:3000/api/v2/products" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `items[].id` | integer | yes | `2` |
| `items[].sku` | string | yes | `"TEA-002"` |
| `items[].name` | string | yes | `"Sencha"` |
| `items[].category` | string | yes | `"mugs"` \| `"tea"` |
| `items[].price_cents` | integer | yes | `1500` |
| `items[].tags[]` | string | yes | `"green"` \| `"insulated"` |
| `items[].price` | string | yes | `"15.00"` |
| `next_cursor` | null | string | yes | `"eyJpZCI6Mn0"` |

```json
{
  "items": [
    {
      "id": 1,
      "sku": "TEA-001",
      "name": "Earl Grey",
      "category": "tea",
      "price_cents": 1200,
      "tags": [
        "black",
        "bergamot"
      ],
      "price": "12.00"
    },
    {
      "id": 2,
      "sku": "TEA-002",
      "name": "Sencha",
      "category": "tea",
      "price_cents": 1500,
      "tags": [
        "green"
      ],
      "price": "15.00"
    }
  ],
  "next_cursor": "eyJpZCI6Mn0"
}
```

---

Resource: [Products](index.md)
