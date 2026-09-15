# Delete Task

`DELETE /api/v1/tasks/:id`

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
curl --request DELETE \
  --url "http://localhost:3000/api/v1/tasks/3" \
  --header "Accept: application/json"
```

## Responses

### 204 No Content

_No response body._

---

Resource: [Tasks](index.md)
