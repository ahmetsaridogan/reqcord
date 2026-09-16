# Capture, sanitization and inference

How a request made by a test ends up as a row in a parameter table.

```text
integration test ──► capture ──► sanitize ──► dataset ──► exporters
                    (in the test    (before       (schemas
                     process)        anything      inferred
                                     is stored)    per endpoint)
```

## Capture

`reqcord:generate` runs the suite in a subprocess with `REQCORD_CAPTURE=1`
and `REQCORD_CAPTURE_FILE=<path>`. Inside that process the Railtie prepends a
patch to `ActionDispatch::Integration::Session#process`, so every `get`,
`post`, `patch`, `put` and `delete` a test makes — through Minitest
integration tests or RSpec request specs — appends one JSON line to the
capture file. The file is append-only and locked per write, so parallel test
workers share it. Without those variables an ordinary `bin/rails test`
patches nothing and writes nothing.

Each line is one **exchange**:

| Field | Source |
| --- | --- |
| `request.method`, `request.path` | the verb and the concrete path the test called (`/api/v2/customers/42`), method-override forms normalized |
| `request.path_params` | the dynamic segments the router filled in (`id: "42"`) |
| `request.query_params` | the query string, nested (`filter: { category: "mugs" }`) |
| `request.headers` | the headers the test passed, plus `Content-Type` / `Accept` when they carry information (Rails' default `Accept` is dropped) |
| `request.body`, `request.content_type` | the params the test sent, as JSON or as form fields |
| `response.status`, `response.headers`, `response.body`, `response.content_type` | the response; JSON bodies parsed, others kept as text |
| `source` | the test method or example name, its class or group, file and line |

Supported request bodies are JSON and form-encoded; multipart uploads are
not captured yet.

## Sanitization

Sanitization runs on every exchange **before** it reaches the dataset, so no
generated file — and not `dataset.json` either — contains a credential.

**Headers** are matched case-insensitively and replaced verbatim with what
you configure:

```yaml
sanitize:
  headers:
    Authorization: "Bearer {{token}}"     # default
    X-Api-Key: "{{api_key}}"              # default
    X-Account-Id: "{{account_id}}"
```

Some headers are redacted whether configured or not: `Authorization`,
`Proxy-Authorization`, `Cookie`, `Set-Cookie`, `X-Api-Key`, `X-Auth-Token`,
`X-Csrf-Token`. Without a configured replacement the value becomes a
placeholder named after the header (`{{cookie}}`), and a `Bearer`, `Token` or
`Basic` scheme is kept so the cURL stays runnable.

Transport noise (`Host`, `User-Agent`, `Content-Length`, `X-Request-Id`,
`X-Runtime`, `ETag`, the `X-*-Options` security headers …) and empty headers
are dropped from requests and responses alike.

**Body keys** are matched case-insensitively at any depth, in requests and
responses:

```yaml
sanitize:
  body:
    password: "{{password}}"      # default, with password_confirmation
    token: "{{token}}"            # default, with access_token, refresh_token
    api_key: "{{api_key}}"        # default
    secret: "{{secret}}"          # default, with client_secret
    payment_url: "{{payment_url}}"
```

The whole value under the key is replaced, whatever its type.

**Placeholders** are the documentation's variables: `{{name}}` stays as-is in
Markdown and cURL, is listed in the index under *Placeholders*, becomes a
collection variable in Postman and feeds the security schemes in OpenAPI.
The full list of rules is in
[configuration.md → sanitize](configuration.md#sanitize).

## Building the dataset

Each exchange is matched against the route table (concrete path → route
pattern, engine mount prefixes included) and attached to that endpoint as a
request example and a response example. Two captures that are identical
after sanitization and produced the same status collapse into one example;
a different status is always kept, so a right and a wrong password are two
examples even though both read `{{password}}`.

## Inference

The parameter tables and response field tables are **inferred**, and only
from the requests the application **accepted** (`2xx`). A request that was
rejected tells you nothing reliable about what the endpoint takes, so its
payload is kept as a response example and nothing more.

For each endpoint, all accepted bodies, query hashes and path parameter
hashes are flattened to field paths and merged:

| Column | Rule |
| --- | --- |
| `Field` | the path: `customer.name`, `order.line_items[].sku`, `filter.category` |
| `Type` | the JSON types seen (`string`, `integer`, `number`, `boolean`, `null`, `object`, `array`), joined with `\|` when they differ |
| `Required` | `yes` only when **every** accepted request carried the field; a request accepted with no parameters at all counts, so `?status=` on a list endpoint is optional |
| `Values` | a closed set (`"active"` \| `"passive"`) when the values look like a choice; otherwise one example |

A field is shown as a closed set when it has 2–6 distinct scalar values, is
not an identifier (`id`, `*_id`, `uuid`, `token`, `slug`, `*_key`), and
either a value repeated across requests or every value reads like a token
(`active`, `pending_review`, `USD`) rather than content (`Ada Lovelace`,
`ada@example.com`, `e-00056197`).

Response fields use the same inference over every body captured with that
status, with one difference: repetition across responses does not make a
set — fixture names that come back in every list response are content, not a
choice — so only the token rule applies. The first body captured for a
status is the example shown.

## What the dataset holds

```json
{
  "schema_version": 2,
  "endpoints": [
    {
      "name": "Create Customer",
      "method": "POST",
      "path": "/api/v2/customers",
      "controller": "api/v2/customers",
      "action": "create",
      "route_name": "api_v2_customers",
      "also_methods": [],
      "parameters": {
        "path": [],
        "query": [],
        "body": [
          { "path": "customer.name",   "type": "string", "required": true, "values": ["John Doe"] },
          { "path": "customer.status", "type": "string", "required": true, "values": ["active", "passive"] }
        ]
      },
      "responses": [
        { "status": 201, "schema": [ { "path": "id", "type": "integer", "required": true, "values": [42] } ],
          "example": { "id": 42, "name": "John Doe" } },
        { "status": 422, "schema": [ "…" ], "example": { "errors": { "email": ["can't be blank"] } } }
      ],
      "request_examples":  [ "every captured request, sanitized, with its source test" ],
      "response_examples": [ "every captured response, sanitized" ]
    }
  ],
  "uncovered_routes": [
    { "method": "DELETE", "path": "/api/v2/customers/:id", "controller": "api/v2/customers", "action": "destroy" }
  ]
}
```

`endpoints` holds the documented ones; everything else is under
`uncovered_routes`. `schema_version` lets the format evolve — readers ignore
keys they do not know.
