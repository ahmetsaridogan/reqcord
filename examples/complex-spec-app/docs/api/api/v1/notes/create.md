# Create Note

`POST /api/v1/orders/:order_id/notes`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Authorization | `Bearer {{token}}` |
| Content-Type | `application/json` |
| Accept | `application/json` |

## Path Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `order_id` | string | yes | `"1"` |

## Body Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `note.body` | string | yes | `"Ring the bell twice"` |

## Example Request

```json
{
  "note": {
    "body": "Ring the bell twice"
  }
}
```

## cURL

```bash
curl --request POST \
  --url "http://localhost:3000/api/v1/orders/1/notes" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "note": {
    "body": "Ring the bell twice"
  }
}'
```

## Responses

### 201 Created

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `3` |
| `order_id` | integer | yes | `1` |
| `body` | string | yes | `"Ring the bell twice"` |
| `author` | string | yes | `"ada"` |

```json
{
  "id": 3,
  "order_id": 1,
  "body": "Ring the bell twice",
  "author": "ada"
}
```

### 422 Unprocessable Content

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `errors.body[]` | string | yes | `"can't be blank"` |

```json
{
  "errors": {
    "body": [
      "can't be blank"
    ]
  }
}
```

---

Resource: [Notes](index.md)
