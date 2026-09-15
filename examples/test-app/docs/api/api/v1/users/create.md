# Create User

`POST /api/v1/users`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Authorization | `Bearer {{token}}` |
| Content-Type | `application/json` |
| Accept | `application/json` |

## Body Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `user.name` | string | yes | `"Ada Lovelace"` |
| `user.email` | string | yes | `"ada@example.com"` |
| `user.status` | string | yes | `"active"` \| `"inactive"` |

## Example Request

```json
{
  "user": {
    "name": "Ada Lovelace",
    "email": "ada@example.com",
    "status": "active"
  }
}
```

## cURL

```bash
curl --request POST \
  --url "http://localhost:3000/api/v1/users" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "user": {
    "name": "Ada Lovelace",
    "email": "ada@example.com",
    "status": "active"
  }
}'
```

## Responses

### 201 Created

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `3` |
| `name` | string | yes | `"Ada Lovelace"` |
| `email` | string | yes | `"ada@example.com"` |
| `status` | string | yes | `"active"` \| `"inactive"` |

```json
{
  "id": 3,
  "name": "Ada Lovelace",
  "email": "ada@example.com",
  "status": "active"
}
```

### 422 Unprocessable Content

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `errors.email[]` | string | no | `"can't be blank"` |
| `errors.status[]` | string | no | `"is not included in the list"` |

```json
{
  "errors": {
    "email": [
      "can't be blank"
    ]
  }
}
```

---

Resource: [Users](index.md)
