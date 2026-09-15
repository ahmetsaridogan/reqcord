# List Tasks

`GET /api/v1/tasks`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Accept | `application/json` |

## Query Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `status` | string | no | `"done"` \| `"open"` |

## cURL

```bash
curl --request GET \
  --url "http://localhost:3000/api/v1/tasks" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `[].id` | integer | yes | `3` |
| `[].title` | string | yes | `"Tidy the backlog"` |
| `[].status` | string | yes | `"done"` \| `"open"` |
| `[].priority` | string | yes | `"high"` \| `"low"` |

```json
[
  {
    "id": 1,
    "title": "Write the docs",
    "status": "open",
    "priority": "high"
  },
  {
    "id": 2,
    "title": "Ship 0.1.1",
    "status": "done",
    "priority": "high"
  },
  {
    "id": 3,
    "title": "Tidy the backlog",
    "status": "open",
    "priority": "low"
  }
]
```

---

Resource: [Tasks](index.md)
