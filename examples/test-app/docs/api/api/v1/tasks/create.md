# Create Task

`POST /api/v1/tasks`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Content-Type | `application/json` |
| Accept | `application/json` |

## Body Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `task.title` | string | yes | `"Review the release"` |
| `task.priority` | string | yes | `"high"` \| `"low"` |

## Example Request

```json
{
  "task": {
    "title": "Review the release",
    "priority": "high"
  }
}
```

## cURL

```bash
curl --request POST \
  --url "http://localhost:3000/api/v1/tasks" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "task": {
    "title": "Review the release",
    "priority": "high"
  }
}'
```

## Responses

### 201 Created

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `4` |
| `status` | string | yes | `"open"` |
| `title` | string | yes | `"Review the release"` |
| `priority` | string | yes | `"high"` \| `"low"` |

```json
{
  "id": 4,
  "status": "open",
  "title": "Review the release",
  "priority": "high"
}
```

### 422 Unprocessable Content

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `errors.title[]` | string | no | `"can't be blank"` |
| `errors.priority[]` | string | no | `"is not included in the list"` |

```json
{
  "errors": {
    "title": [
      "can't be blank"
    ]
  }
}
```

---

Resource: [Tasks](index.md)
