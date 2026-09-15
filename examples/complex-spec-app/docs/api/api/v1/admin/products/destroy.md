# Delete Product

`DELETE /api/v1/admin/products/:id`

Namespace: `api/v1/admin`

## Headers

| Header | Value |
| --- | --- |
| X-Api-Key | `{{api_key}}` |
| Accept | `application/json` |

## Path Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | string | yes | `"4"` |

## cURL

```bash
curl --request DELETE \
  --url "http://localhost:3000/api/v1/admin/products/4" \
  --header "X-Api-Key: {{api_key}}" \
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

Resource: [Products](index.md)
