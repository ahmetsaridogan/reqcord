# List Notes

`GET /api/v1/orders/:order_id/notes`

Namespace: `api/v1`

## Headers

| Header | Value |
| --- | --- |
| Authorization | `Bearer {{token}}` |
| Accept | `application/json` |

## Path Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `order_id` | string | yes | `"1"` |

## cURL

```bash
curl --request GET \
  --url "http://localhost:3000/api/v1/orders/1/notes" \
  --header "Authorization: Bearer {{token}}" \
  --header "Accept: application/json"
```

## Responses

### 200 OK

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `[].id` | integer | yes | `2` |
| `[].order_id` | integer | yes | `1` |
| `[].body` | string | yes | `"Gift wrap please"` |
| `[].author` | string | yes | `"ada"` |

```json
[
  {
    "id": 1,
    "order_id": 1,
    "body": "Leave at the door",
    "author": "ada"
  },
  {
    "id": 2,
    "order_id": 1,
    "body": "Gift wrap please",
    "author": "ada"
  }
]
```

---

Resource: [Notes](index.md)
