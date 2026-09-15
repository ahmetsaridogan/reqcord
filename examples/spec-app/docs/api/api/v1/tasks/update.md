# Update Task

`PATCH /api/v1/tasks/:id` (also `PUT`)

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Content-Type | `application/json` |
| Accept | `application/json` |

## Path Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | string | yes | `"1"` |

## Body Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `task.title` | string | yes | `"Write better docs"` |

## Example Request

```json
{
  "task": {
    "title": "Write better docs"
  }
}
```

## cURL

```bash
curl --request PATCH \
  --url "http://localhost:3000/api/v1/tasks/1" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "task": {
    "title": "Write better docs"
  }
}'
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `1` |
| `title` | string | yes | `"Write better docs"` |
| `status` | string | yes | `"open"` |
| `priority` | string | yes | `"high"` |

```json
{
  "id": 1,
  "title": "Write better docs",
  "status": "open",
  "priority": "high"
}
```

---

Resource: [Tasks](index.md)
