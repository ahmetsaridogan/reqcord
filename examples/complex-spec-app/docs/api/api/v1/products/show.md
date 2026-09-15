# Get Product

`GET /api/v1/products/:id`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Accept | `application/json` |

## Path Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | string | yes | `"3"` |

## cURL

```bash
curl --request GET \
  --url "http://localhost:3000/api/v1/products/3" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `3` |
| `sku` | string | yes | `"MUG-001"` |
| `name` | string | yes | `"Stoneware Mug"` |
| `category` | string | yes | `"mugs"` |
| `price_cents` | integer | yes | `2400` |
| `tags[]` | string | yes | `"ceramic"` |

```json
{
  "id": 3,
  "sku": "MUG-001",
  "name": "Stoneware Mug",
  "category": "mugs",
  "price_cents": 2400,
  "tags": [
    "ceramic"
  ]
}
```

### 404 Not Found

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `error` | string | yes | `"Not Found"` |

```json
{
  "error": "Not Found"
}
```

---

Resource: [Products](index.md)
