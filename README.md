# Reqcord

[![CI](https://github.com/ahmetsaridogan/reqcord/actions/workflows/ci.yml/badge.svg)](https://github.com/ahmetsaridogan/reqcord/actions/workflows/ci.yml)

**Turn your Rails integration tests into living API documentation.**

Reqcord observes real HTTP requests and responses executed by your Rails test suite and converts them into static, readable API documentation.

Instead of maintaining API documentation separately from your tests, Reqcord uses the requests your application already executes as the source of truth.

```text
Rails Routes
     +
Minitest Integration Tests
          ↓
    Request Capture
          ↓
    Response Capture
          ↓
      Sanitization
          ↓
   Canonical Dataset
          ↓
   Markdown · cURL · Postman · OpenAPI (Scalar)
```

## Why Reqcord?

API documentation tends to drift away from the application it describes.

A request changes.

A header is added.

A validation rule changes.

A new `422` response appears.

The tests are updated, but the documentation is forgotten.

Reqcord takes a different approach:

> If your tests already know how to call your API, they already contain most of the information required to document it.

Reqcord captures that information and turns it into static API documentation.

No separate documentation DSL.

No duplicate request definitions.

No manually maintained cURL examples.

Your tests remain normal Rails tests.

## Example

Given an existing Rails integration test:

```ruby
test "creates customer" do
  post "/api/v2/customers",
    params: {
      customer: {
        name: "John Doe",
        email: "john@example.com"
      }
    },
    headers: {
      "Authorization" => "Bearer test-token",
      "X-Account-Id" => "42"
    },
    as: :json

  assert_response :created
end
```

Reqcord captures the request and response while the test executes.

It can generate documentation such as:

````markdown
# Create Customer

`POST /api/v2/customers`

## Headers

| Header | Value |
| --- | --- |
| Authorization | `Bearer {{token}}` |
| X-Account-Id | `{{account_id}}` |
| Content-Type | `application/json` |

## Body Parameters

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `customer.name` | string | yes | `"John Doe"` |
| `customer.email` | string | yes | `"john@example.com"` |
| `customer.status` | string | yes | `"active"` \| `"passive"` |

## Example Request

```json
{
  "customer": {
    "name": "John Doe",
    "email": "john@example.com",
    "status": "active"
  }
}
```

## cURL

```bash
curl --request POST \
  --url "http://localhost:3000/api/v2/customers" \
  --header "Authorization: Bearer {{token}}" \
  --header "X-Account-Id: {{account_id}}" \
  --header "Content-Type: application/json" \
  --data '{
  "customer": {
    "name": "John Doe",
    "email": "john@example.com",
    "status": "active"
  }
}'
```

## Responses

### 201 Created

#### Fields

| Field | Type | Required | Values |
| --- | --- | --- | --- |
| `id` | integer | yes | `42` |
| `name` | string | yes | `"John Doe"` |

```json
{
  "id": 42,
  "name": "John Doe"
}
```

### 401 Unauthorized

```json
{
  "error": "Unauthorized"
}
```

### 422 Unprocessable Content

```json
{
  "errors": {
    "email": [
      "has already been taken"
    ]
  }
}
```
````

The parameter tables are inferred from the requests the application
**accepted**: two passing tests sent `"active"` and `"passive"`, a third sent
`"inactive"` and got a `422`, so the documentation lists the two values that
work and keeps the rejection only as a response example. The same run also
writes a runnable `curl/api/v2/customers/create.sh`, a Postman collection
with this request and its three saved responses, and an OpenAPI 3.1 document
you can browse with Scalar by mounting `Reqcord::Web` (see
[Serve the docs in your app](#serve-the-docs-in-your-app)).

## Examples

Two runnable examples live in [`examples/`](examples):

| Example | Test framework | What it shows |
| --- | --- | --- |
| [`examples/test-app`](examples/test-app) | Minitest | three small resources: auth, closed value sets, PATCH/PUT folding, a member action |
| [`examples/spec-app`](examples/spec-app) | RSpec | the same API, documented from request specs |
| [`examples/complex-test-app`](examples/complex-test-app) | Minitest | a store API: products, cart, orders, nested notes, array bodies, `filter[category]`, a form login, `X-Api-Key` admin namespace, two API versions, 400/403/404/409 |
| [`examples/complex-spec-app`](examples/complex-spec-app) | RSpec | the store API from request specs |

Each one ships the documentation it generates, so you can read the output
before running anything. [`examples/reqcord.yml`](examples/reqcord.yml) is an
annotated configuration file.

## Core Idea

Reqcord separates **capturing API behavior** from **rendering documentation**.

```text
                  Rails Routes
                       │
                       ▼
                Route Collector
                       │
Minitest ──────► Test Adapter
                       │
                       ▼
                Reqcord Dataset
                       │
          ┌────────────┼────────────┬────────────┐
          ▼            ▼            ▼            ▼
      Markdown       cURL        Postman      OpenAPI ──► Scalar
```

The internal dataset is framework-independent and output-independent.

This allows Reqcord to support additional test frameworks and documentation formats without coupling them together.

## Supported versions

| | |
| --- | --- |
| Ruby | 3.2, 3.3, 3.4 |
| Rails | 7.1, 7.2, 8.0, 8.1 |
| Test frameworks | Minitest integration tests, RSpec request specs |

Every Ruby × Rails pair that Rails itself supports runs in CI
(`gemfiles/rails_*.gemfile`).

## Installation

Add Reqcord to the development and test groups:

```ruby
group :development, :test do
  gem "reqcord"
end
```

Then run:

```bash
bundle install
```

Initialize Reqcord:

```bash
bin/rails reqcord:init
```

This creates:

```text
reqcord.yml
docs/
└── api/
```

## Configuration

Reqcord reads its configuration from `reqcord.yml` in the project root. Every
key, default and environment override is described in
[docs/configuration.md](docs/configuration.md); the short version:

```yaml
version: 1

test:
  framework: minitest   # or: rspec

routes:
  prefix: /api

output:
  directory: docs/api

exporters:
  - curl
  - markdown
  - postman
  - openapi

variables:
  base_url: http://localhost:3000

sanitize:
  headers:
    Authorization: "Bearer {{token}}"
    X-Account-Id: "{{account_id}}"
```

Configuration precedence:

```text
CLI / Environment
        ↓
reqcord.yml
        ↓
Reqcord defaults
```

## Generating Documentation

Generate documentation for the entire API:

```bash
bin/rails reqcord:generate
```

Generate documentation for a specific resource:

```bash
bin/rails reqcord:generate RESOURCE=customers
```

Multiple resources:

```bash
bin/rails reqcord:generate RESOURCE=customers,surveys
```

Filter by API version:

```bash
bin/rails reqcord:generate VERSION=v2
```

Combine filters:

```bash
bin/rails reqcord:generate RESOURCE=customers VERSION=v2
```

`reqcord:generate` runs the test suite itself, in a subprocess, with capture
enabled:

```text
bin/rails reqcord:generate
        |
        +-- collects the application's routes
        |
        +-- runs `test.command` with REQCORD_CAPTURE=1
        |          |
        |          +-- each request appends a JSON line to the capture file
        |
        +-- reads the capture file, sanitizes, writes the documentation
```

Because capture is driven by `REQCORD_CAPTURE` and `REQCORD_CAPTURE_FILE`, an
ordinary `bin/rails test` patches nothing and writes nothing. The capture file
is append-only and locked per write, so parallel test workers can share it.

Point Reqcord at the tests that exercise the API — a directory is enough, it
picks the runner (`bin/rails test`, `rspec`, or a plain Ruby runner when the
project has no `bin/rails`):

```yaml
test:
  framework: minitest
  paths:
    - test/integration
    - test/api
```

Or spell the command out; it wins over `paths`, and globs are expanded:

```yaml
test:
  command: bin/rails test test/integration test/api/*_test.rb
```

The run ends with a reconciliation of the whole route table, so nothing can
go missing quietly:

```text
[reqcord] captured 87 request(s), 85 matched a documented route
[reqcord] captured a successful 2xx request for 15 of 16 endpoint(s)
[reqcord] routes: 18 = 15 documented + 1 uncovered + 2 skipped
[reqcord] skipped 2 route(s) that cannot be documented: 1 redirect, 1 mount
```

Every route is in exactly one bucket: *documented* (a test got a `2xx`),
*uncovered* (listed in the index, no page), or *skipped* with its reason.

## Generated Files

Directories follow the controller path, so `admin/customers` and
`api/v2/customers` never collide:

```text
docs/api/
├── dataset.json
├── README.md
├── api/v2/customers/
│   ├── index.md
│   ├── create.md
│   ├── show.md
│   └── update.md
├── api/v2/surveys/
│   ├── index.md
│   └── list.md
├── curl/
│   └── api/v2/customers/
│       ├── create.sh
│       └── show.sh
├── postman/
│   └── collection.json
└── openapi/
    └── openapi.json
```

`dataset.json` contains Reqcord's normalized representation of the captured
API; every exporter reads that and nothing else.

## Route coverage

The documented surface is the route table, not only `resources`. These all
become endpoints:

| Route | Documented as |
| --- | --- |
| `resources :customers` | one endpoint per action |
| `resource :cart` | `GET /cart`, `PATCH /cart` (also `PUT`) |
| `match "/echo", via: [:get, :post]` | `GET /echo` and `POST /echo` |
| `match "/anything", via: :all` | one endpoint per verb the tests used |
| `root to: "home#index"` | `GET /`, titled "Home" |
| `get "/items(/:id)"` | one endpoint, `:id` optional |
| `get "/files/*path"` | `path` as a path parameter |
| `mount Billing => "/billing"` | the engine's own routes, under `/billing` |
| `namespace :admin { resources :customers }` | `admin/customers/`, apart from `api/v2/customers/` |

`redirect(...)` routes and plain Rack mounts cannot be documented from a test;
they are counted as *skipped* in the report rather than dropped.

## Postman and Hoppscotch

`postman/collection.json` is a Postman Collection v2.1:

* one folder per controller namespace (`Api › V2 › Customers`),
* one request per documented endpoint, built from the successful captured
  example — JSON bodies as `raw`, form bodies as `urlencoded`,
* every captured status saved as a response example on that request,
* collection variables for `base_url` and every placeholder the sanitizer
  wrote (`{{token}}`, `{{api_key}}` …) — Postman's variable syntax is the
  same, so the collection is usable as soon as the variables are filled in,
* `Authorization: Bearer {{token}}` lifted to collection-level bearer auth;
  requests that were made without credentials are marked `noauth`, so they
  replay exactly as their tests did.

Hoppscotch imports Postman v2.1 collections directly: *Import → Postman* and
point it at the same file.

## OpenAPI

`openapi/openapi.json` is an OpenAPI 3.1 document built from the same dataset:

* one path item per documented route, in OpenAPI notation — `/customers/:id`
  becomes `/customers/{id}`, and `/items(/:id)` becomes both `/items` and
  `/items/{id}`,
* path and query parameters from the inferred schemas, closed value sets as
  `enum`,
* a `requestBody` (`application/json` or `application/x-www-form-urlencoded`,
  whichever the test sent) whose JSON Schema is rebuilt from the field paths,
  nested objects and arrays included, `required` from what every accepted
  request carried,
* one response per captured status with its schema and example,
* `bearerAuth` / `apiKeyAuth` security schemes derived from the sanitized
  `Authorization` and `X-Api-Key` headers, applied per operation — so public
  endpoints stay public.

Anything that reads OpenAPI (Scalar, Swagger UI, Redoc, code generators) can
consume the file as is.

## Serve the docs in your app

`Reqcord::Web` is a Rack application that serves the generated output from
inside the Rails app, the way `Sidekiq::Web` does:

```ruby
# config/routes.rb
mount Reqcord::Web => "/api-docs" if Rails.env.development?
```

* `/api-docs` renders `openapi/openapi.json` with
  [Scalar](https://scalar.com) — a searchable reference with a *Try it*
  client, loaded from the Scalar CDN,
* `/api-docs/openapi/openapi.json`, `/api-docs/dataset.json`,
  `/api-docs/postman/collection.json`, `/api-docs/api/v2/customers/create.md`,
  `/api-docs/curl/api/v2/customers/create.sh` … serve the generated files,
* nothing outside `output.directory` is ever served.

`Reqcord::Web` only reads; run `bin/rails reqcord:generate` first (before the
first run the page tells you so). Because the files are static, mounting it
in production is a deployment decision, not a Reqcord one — guard it as you
would any internal page.

## Request Capture

Reqcord captures HTTP information from Rails integration tests.

The initial version supports:

* HTTP method
* Request path
* Path parameters
* Query parameters
* Request headers
* JSON request bodies
* Content type
* Response status
* Response headers
* JSON response bodies
* Test name and source
* Multiple request/response examples per endpoint

Supported HTTP methods:

```text
GET
POST
PUT
PATCH
DELETE
```

## Multiple Responses

Reqcord does not assume that an endpoint has only one response.

For example:

```ruby
test "creates customer" do
  # ...
  assert_response :created
end

test "requires authentication" do
  # ...
  assert_response :unauthorized
end

test "rejects duplicate email" do
  # ...
  assert_response :unprocessable_entity
end
```

can produce:

```text
POST /api/v2/customers

Responses
├── 201 Created
├── 401 Unauthorized
└── 422 Unprocessable Entity
```

Every distinct body captured for a status is kept in `dataset.json`, and the
fields of a response are inferred from all of them:

```text
422 Unprocessable Content
├── Email already exists
├── Name is required
└── Invalid phone number
```

The Markdown page shows one example body per status plus the inferred field
table; Reqcord does not overwrite one `422` example with another.

## Sanitization

Captured tests may contain credentials or other sensitive values.

Reqcord must never blindly write those values into generated documentation.

Sensitive headers can be replaced with variables:

```yaml
sanitize:
  headers:
    Authorization: "Bearer {{token}}"
    X-Api-Key: "{{api_key}}"
    X-Account-Id: "{{account_id}}"
```

A captured request such as:

```text
Authorization: Bearer eyJhbGciOi...
```

becomes:

```text
Authorization: Bearer {{token}}
```

Sensitive headers such as authorization credentials, cookies and API keys are treated specially by Reqcord.

Request and response bodies follow the same principle, matched by key at any
depth:

```yaml
sanitize:
  body:
    password: "{{password}}"
    access_token: "{{token}}"
```

## Canonical Dataset

Reqcord does not directly convert Minitest tests into Markdown.

Instead:

```text
Minitest
   ↓
Test Adapter
   ↓
Canonical Dataset
   ↓
Exporter
```

A simplified endpoint representation looks like:

```json
{
  "name": "Create Customer",
  "method": "POST",
  "path": "/api/v2/customers",
  "controller": "api/v2/customers",
  "action": "create",
  "parameters": {
    "path": [],
    "query": [],
    "body": [
      { "path": "customer.name", "type": "string", "required": true, "values": ["John Doe"] },
      { "path": "customer.status", "type": "string", "required": true, "values": ["active", "passive"] }
    ]
  },
  "responses": [
    {
      "status": 201,
      "schema": [
        { "path": "id", "type": "integer", "required": true, "values": [42] }
      ],
      "example": { "id": 42, "name": "John Doe" }
    },
    { "status": 401, "schema": [ { "path": "error", "type": "string", "required": true, "values": ["Unauthorized"] } ], "example": { "error": "Unauthorized" } }
  ],
  "request_examples": [ "… every captured request, sanitized" ],
  "response_examples": [ "… every captured response, sanitized" ]
}
```

`parameters` and `responses[].schema` are inferred only from requests the
application accepted; `request_examples` keeps everything that was captured.
Routes no test reached are listed separately under `uncovered_routes`.

Every dataset contains a schema version so the internal format can evolve safely.

```json
{
  "schema_version": 2
}
```

## Architecture

```text
Reqcord
├── Configuration
├── Dataset
│   ├── Resource         (one controller path, nested directories/folders)
│   ├── Endpoint
│   ├── RequestExample
│   ├── ResponseExample
│   └── Schema           (fields, types, required, closed value sets)
│
├── RouteCollector       (every route kind, engines walked, skips counted)
│
├── Capture
│   ├── Collector        (NDJSON, one line per exchange)
│   ├── TestContext
│   ├── MinitestContext / RSpecContext
│   └── IntegrationPatch
│
├── Generator            (run tests → dataset → exporters → report)
│
├── Sanitizers
│   └── Sanitizer        (headers and bodies)
│
├── Renderers
│   ├── Payload          (JSON vs form, nested query flattening)
│   └── Curl
│
├── Exporters
│   ├── Markdown
│   ├── Curl             (one .sh per endpoint)
│   ├── Postman          (Collection v2.1, also for Hoppscotch)
│   └── Openapi          (OpenAPI 3.1)
│
└── Web                  (Rack app: Scalar page + generated files)
```

Test adapters are responsible only for converting test execution into Reqcord's canonical model.

Exporters know nothing about Minitest or Rails test internals.

```text
Minitest ──┐
           │
RSpec ─────┼──► Dataset ──► Markdown
           │             ├─► cURL
Other ─────┘             ├─► Postman  (→ Hoppscotch)
                         └─► OpenAPI  (→ Scalar via Reqcord::Web)
```

## v0.1 Scope

The first Reqcord release focuses on proving the capture pipeline.

### Included

* Rails 8
* Minitest integration tests
* RSpec request specs
* Rails route discovery
* `reqcord.yml`
* Request capture
* Response capture
* Multiple response scenarios
* Sensitive data sanitization
* Canonical `dataset.json` with inferred request parameters and response fields
* Markdown documentation
* Generated cURL requests (in the Markdown and as runnable `.sh` files)
* Postman Collection v2.1 (imports into Hoppscotch as well)
* OpenAPI 3.1 document, browsable with Scalar through `mount Reqcord::Web`
* The whole route table: custom actions, `match via:`, `via: :all`,
  singular resources, optional segments and globs, mounted engines
* Resource filtering
* API version filtering

### Not included yet

* Multipart requests
* CI documentation drift detection

These features belong to later releases rather than expanding the initial scope.

## Roadmap

### v0.3

Rack::Test capture, so frameworks other than Rails (Sinatra, Roda, Hanami) can
be documented from the same dataset.

### Future

Potential exporters and integrations include:

* Bruno
* Insomnia
* `llms.txt`
* Static HTML documentation
* JSON Schema
* CI documentation drift detection

## Design Principles

**Tests are the source of truth.**

Reqcord should observe existing tests instead of forcing developers to rewrite them using a documentation-specific DSL.

**Capture once, export anywhere.**

Test execution produces a framework-independent dataset. Exporters operate exclusively on that dataset.

**Generated documentation must be safe.**

Credentials and sensitive data must not leak into generated files.

**Generated documentation must be useful without a server.**

Markdown and cURL output should remain readable directly from GitHub or a local checkout.

**Adapters stay isolated.**

Minitest, RSpec, Markdown, OpenAPI and other integrations should not depend directly on each other.

## Status

Reqcord is currently in early development.

The initial goal is intentionally narrow:

> Capture real Rails API requests and responses from the test suite and generate accurate, sanitized Markdown documentation, executable cURL examples, a Postman collection and an OpenAPI document — without the developer writing any of them by hand.

Once that pipeline is reliable, additional adapters and exporters can be built on top of the same dataset.

## License

Reqcord is available as open source under the terms of the MIT License.

## cURL source of truth

Reqcord does not invent request payloads. For Rails integration tests, the
arguments passed to `get`, `post`, `put`, `patch`, and `delete` are captured at
runtime. Generated cURL commands use a successful `2xx` test case whenever one
exists, including its concrete URL, request headers, query parameters, and
payload. Error-case payloads remain available as examples but do not replace
the canonical successful request.
