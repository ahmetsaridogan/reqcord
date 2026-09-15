# Delete Order

`DELETE /api/v1/orders/:id`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Authorization | `Bearer {{token}}` |
| Accept | `application/json` |

## Path Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | string | yes | `"1"` |

## cURL

```bash
curl --request DELETE \
  --url "http://localhost:3000/api/v1/orders/1" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
```

## Responses

### 204 No Content

_No response body._

---

Resource: [Orders](index.md)
