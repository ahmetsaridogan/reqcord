# Home

`GET /api/v1`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Accept | `application/json` |

## cURL

```bash
curl --request GET \
  --url "http://localhost:3000/api/v1" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `name` | string | yes | `"Store API"` |
| `version` | string | yes | `"v1"` |
| `links.products` | string | yes | `"/api/v1/products"` |
| `links.orders` | string | yes | `"/api/v1/orders"` |

```json
{
  "name": "Store API",
  "version": "v1",
  "links": {
    "products": "/api/v1/products",
    "orders": "/api/v1/orders"
  }
}
```

---

Resource: [Home](index.md)
