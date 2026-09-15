# Get Task

`GET /api/v1/tasks/:id`

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
curl --request GET \
  --url "http://localhost:3000/api/v1/tasks/1" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `1` |
| `title` | string | yes | `"Write the docs"` |
| `status` | string | yes | `"open"` |
| `priority` | string | yes | `"high"` |

```json
{
  "id": 1,
  "title": "Write the docs",
  "status": "open",
  "priority": "high"
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

Resource: [Tasks](index.md)
