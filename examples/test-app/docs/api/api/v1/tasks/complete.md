# Complete Task

`POST /api/v1/tasks/:id/complete`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Accept | `application/json` |

## Path Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | string | yes | `"1"` |

## cURL

```bash
curl --request POST \
  --url "http://localhost:3000/api/v1/tasks/1/complete" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `1` |
| `title` | string | yes | `"Write the docs"` |
| `status` | string | yes | `"done"` |
| `priority` | string | yes | `"high"` |

```json
{
  "id": 1,
  "title": "Write the docs",
  "status": "done",
  "priority": "high"
}
```

---

Resource: [Tasks](index.md)
