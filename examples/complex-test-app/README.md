# complex-test-app (Minitest)

A store API in one file, with ordinary Minitest integration tests, chosen to
show the harder things Reqcord documents. Start with [test-app](../test-app)
if you want the gentle version.

| Endpoint | What it shows in the output |
| --- | --- |
| `GET /api/v1` | `root` inside a namespace, titled "Home" |
| `POST /api/v1/auth/login` | a **form** post (`urlencoded` in Postman, `--data 'email=…'` in cURL); the `token` in the response is sanitized to `{{token}}` |
| `GET` / `PATCH /api/v1/profile` | singular `resource`; `PATCH` and `PUT` folded into one page |
| `GET /api/v1/products` | nested query `filter[category]`, an optional `sort` with a closed set (`"price_asc" \| "price_desc"`), `page` / `per_page` |
| `GET /api/v1/products/search` | collection action, `400` without `q` |
| `POST /api/v1/orders` | an array body: `order.line_items[].sku`, `order.shipping_address.city` |
| `GET /api/v1/orders/:id` | `403` for another customer's order, `404` |
| `POST /api/v1/orders/:id/cancel` | member action, `409` once shipped |
| `GET /api/v1/orders/:order_id/notes` | nested resource, `order_id` as a path parameter |
| `GET /api/v1/cart` | singular `resource :cart` — one record, no id |
| `POST` / `DELETE /api/v1/cart/items/:sku` | items nested under the cart, addressed by `sku` (`param: :sku`) |
| `POST /api/v1/cart/checkout` | custom action on a singular resource ("Checkout Cart"), `payment_method` as `"bank_transfer" \| "card"` |
| `/api/v1/admin/products` | a second credential (`X-Api-Key` → `{{api_key}}`), its own `admin` folder, `409` on a duplicate sku |
| `POST /api/v1/admin/products/:product_id/image` | a **multipart** upload: `image` is typed `file`, shown by name (`label.png`), `--form image=@label.png` in cURL, `formdata` in Postman, `format: binary` in OpenAPI |
| `GET /api/v2/products` | a second API version next to the first: `VERSION=v2 ruby generate.rb` |

Every route is covered by a test, so the report ends in
`routes: 23 = 23 documented + 0 uncovered + 0 skipped`.

```text
app.rb                     the application
test/integration/*_test.rb ordinary integration tests
reqcord.yml                paths, prefix, two sanitized headers and two body keys
docs/api/                  generated Markdown, cURL scripts, Postman collection
```

## Regenerate

```bash
ruby generate.rb
RESOURCE=orders,notes ruby generate.rb
VERSION=v2 ruby generate.rb
```
