# Create Customer

`POST /api/v1/customers`

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
| `customer.name` | string | yes | `"Ada Lovelace"` |
| `customer.email` | string | yes | `"ada@example.com"` |
| `customer.status` | string | yes | `"active"` \| `"passive"` |

## Example Request

```json
{
  "customer": {
    "name": "Ada Lovelace",
    "email": "ada@example.com",
    "status": "active"
  }
}
```

## cURL

```bash
curl --request POST \
  --url "http://localhost:3000/api/v1/customers" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "customer": {
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
| `status` | string | yes | `"active"` \| `"passive"` |

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

Resource: [Customers](index.md)
