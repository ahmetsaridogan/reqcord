# Create Product Image

`POST /api/v1/admin/products/:product_id/image`

Namespace: `api/v1/admin`

## Headers

| Header | Value |
| --- | --- |
| X-Api-Key | `{{api_key}}` |
| Content-Type | `multipart/form-data` |

## Path Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `product_id` | string | yes | `"1"` |

## Body Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `image` | file | yes | `"label.png"` |
| `alt` | string | yes | `"Stoneware mug on a table"` |

## Example Request

Sent as `multipart/form-data`; file parts are shown by name, the cURL below attaches them with `--form`.

```json
{
  "image": "label.png (image/png)",
  "alt": "Stoneware mug on a table"
}
```

## cURL

```bash
curl --request POST \
  --url "http://localhost:3000/api/v1/admin/products/1/image" \
  --header "X-Api-Key: {{api_key}}" \
  --form 'image=@label.png;type=image/png' \
  --form 'alt=Stoneware mug on a table'
```

## Responses

### 201 Created

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `product_id` | integer | yes | `1` |
| `filename` | string | yes | `"label.png"` |
| `content_type` | string | yes | `"image/png"` |
| `alt` | string | yes | `"Stoneware mug on a table"` |

```json
{
  "product_id": 1,
  "filename": "label.png",
  "content_type": "image/png",
  "alt": "Stoneware mug on a table"
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

Resource: [Product Images](index.md)
