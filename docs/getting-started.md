# Getting started

Reqcord documents an API from the integration tests that already exercise it.
Nothing in the tests changes; Reqcord runs them, watches the requests they
make, and writes the documentation from what it saw.

## 1. Install

```ruby
# Gemfile
group :development, :test do
  gem "reqcord"
end
```

```bash
bundle install
```

Both groups matter: `reqcord:generate` runs in development, the capture runs
inside the test process.

## 2. Create the configuration

```bash
bin/rails reqcord:init
```

This writes an annotated `reqcord.yml` (never overwriting one that exists)
and creates `docs/api/`. The two keys worth checking before the first run:

```yaml
test:
  framework: minitest     # or: rspec
  paths:
    - test/integration    # where the tests that call the API live

routes:
  prefix: /api            # only routes under this prefix are documented
```

Every key is described in [configuration.md](configuration.md).

## 3. Generate

```bash
bin/rails reqcord:generate
```

Reqcord collects the route table, runs the tests under `test.paths` in a
subprocess with capture enabled, sanitizes what was captured and writes every
exporter. The run ends with a reconciliation of the whole route table:

```text
[reqcord] captured 87 request(s), 85 matched a documented route
[reqcord] captured a successful 2xx request for 15 of 16 endpoint(s)
[reqcord] routes: 18 = 15 documented + 1 uncovered + 2 skipped
[reqcord] skipped 2 route(s) that cannot be documented: 1 redirect, 1 mount
```

Every route is in exactly one bucket:

| Bucket | Meaning |
| --- | --- |
| documented | a test got a `2xx` from it — it has a page, a cURL script, a Postman request and an OpenAPI operation |
| uncovered | the route exists, but no test reached it with a `2xx`; listed in the index and in `dataset.json` |
| skipped | `redirect(...)` routes and plain Rack mounts, which no test can document |

A red suite still produces documentation from what its green tests captured
(see [`test.strict`](configuration.md#teststrict) to abort instead).

## 4. Read the output

```text
docs/api/
├── README.md                      index: placeholders, resources, endpoints, gaps
├── dataset.json                   the canonical dataset every exporter reads
├── api/v2/customers/
│   ├── index.md                   one page per controller path
│   └── create.md                  one page per endpoint
├── curl/api/v2/customers/
│   └── create.sh                  runnable, sanitized
├── postman/collection.json        Postman v2.1, also for Hoppscotch
└── openapi/openapi.json           OpenAPI 3.1
```

An endpoint page looks like this:

````markdown
# Create Customer

`POST /api/v2/customers`

## Headers

| Header | Value |
| --- | --- |
| Authorization | `Bearer {{token}}` |
| Content-Type | `application/json` |

## Body Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `customer.name` | string | yes | `"John Doe"` |
| `customer.email` | string | yes | `"john@example.com"` |
| `customer.status` | string | yes | `"active"` \| `"passive"` |

## cURL

```bash
curl --request POST \
  --url "http://localhost:3000/api/v2/customers" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --data '{"customer":{"name":"John Doe","email":"john@example.com","status":"active"}}'
```

## Responses

### 201 Created
### 401 Unauthorized
### 422 Unprocessable Content
````

The parameter table comes from the requests the application **accepted**: two
tests sent `"active"` and `"passive"`, a third sent `"inactive"` and got a
`422`, so the page lists the two values that work and keeps the rejection as a
response example. [capture.md](capture.md) explains the rules.

## 5. Browse it in the app (optional)

```ruby
# config/routes.rb
mount Reqcord::Web => "/api-docs" if Rails.env.development?
```

`/api-docs` renders the OpenAPI document with Scalar and serves every other
generated file. See [web.md](web.md).

## 6. Keep it current in CI

The output is a function of the routes and the tests, so it can be checked
like generated code:

```bash
bin/rails reqcord:check
```

It regenerates into a scratch directory, compares with `docs/api` file by
file and exits `1` with a git-status style list when they differ:

```text
Reqcord: /app/docs/api is out of date.

  M api/v2/customers/create.md
  A api/v2/customers/destroy.md
  D curl/api/v2/orders/cancel.sh

Run `bin/rails reqcord:generate` and commit the result.
```

```yaml
# .github/workflows/ci.yml
- run: bin/rails reqcord:check
```

A PR that changes a request or a response without regenerating the docs goes
red; `bin/rails reqcord:generate` and a commit fix it.

## Narrowing a run

```bash
bin/rails reqcord:generate RESOURCE=customers
bin/rails reqcord:generate RESOURCE=customers,cart
bin/rails reqcord:generate VERSION=v2
bin/rails reqcord:routes                  # what would be documented, without running anything
```

## Next

* [configuration.md](configuration.md) — every key in `reqcord.yml`
* [exporters.md](exporters.md) — what each output format contains
* [route-coverage.md](route-coverage.md) — how the route table becomes endpoints
* [troubleshooting.md](troubleshooting.md) — when the output looks thin
* [`examples/`](../examples) — four runnable applications with their generated docs committed
