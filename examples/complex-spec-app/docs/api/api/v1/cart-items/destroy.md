# Delete Cart Item

`DELETE /api/v1/cart/items/:sku`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Authorization | `Bearer {{token}}` |
| Accept | `application/json` |

## Path Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `sku` | string | yes | `"TEA-001"` |

## cURL

```bash
curl --request DELETE \
  --url "http://localhost:3000/api/v1/cart/items/TEA-001" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
```

## Responses

### 204 No Content

_No response body._

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

Resource: [Cart Items](index.md)
