# Update Profile

`PATCH /api/v1/profile` (also `PUT`)

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
| `profile.name` | string | yes | `"Ada L."` |
| `profile.locale` | string | yes | `"tr"` |

## Example Request

```json
{
  "profile": {
    "name": "Ada L.",
    "locale": "tr"
  }
}
```

## cURL

```bash
curl --request PATCH \
  --url "http://localhost:3000/api/v1/profile" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "profile": {
    "name": "Ada L.",
    "locale": "tr"
  }
}'
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `1` |
| `name` | string | yes | `"Ada L."` |
| `email` | string | yes | `"ada@example.com"` |
| `locale` | string | yes | `"tr"` |

```json
{
  "id": 1,
  "name": "Ada L.",
  "email": "ada@example.com",
  "locale": "tr"
}
```

### 422 Unprocessable Content

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `errors.locale[]` | string | yes | `"is not included in the list"` |

```json
{
  "errors": {
    "locale": [
      "is not included in the list"
    ]
  }
}
```

---

Resource: [Profiles](index.md)
