# Reqcord

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
   Markdown API Docs
          ↓
     cURL Examples
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

## Request Body

```json
{
  "customer": {
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

## cURL

```bash
curl --request POST \
  --url "{{base_url}}/api/v2/customers" \
  --header "Authorization: Bearer {{token}}" \
  --header "X-Account-Id: {{account_id}}" \
  --header "Content-Type: application/json" \
  --data '{
    "customer": {
      "name": "John Doe",
      "email": "john@example.com"
    }
  }'
```

## Responses

### 201 Created

```json
{
  "id": 42,
  "name": "John Doe",
  "email": "john@example.com"
}
```

### 401 Unauthorized

```json
{
  "error": "Unauthorized"
}
```

### 422 Unprocessable Entity

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
             ┌─────────┴─────────┐
             ▼                   ▼
         Markdown              JSON
             │
             ▼
           cURL
```

The internal dataset is framework-independent and output-independent.

This allows Reqcord to support additional test frameworks and documentation formats without coupling them together.

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

Reqcord reads its configuration from `reqcord.yml` in the project root.

```yaml
version: 1

test:
  framework: minitest

routes:
  prefix: /api

output:
  directory: docs/api

exporters:
  - markdown

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

## Generated Files

A typical output looks like:

```text
docs/api/
├── dataset.json
├── README.md
├── customers/
│   ├── index.md
│   ├── create.md
│   ├── show.md
│   ├── update.md
│   └── destroy.md
└── surveys/
    ├── index.md
    └── create.md
```

`dataset.json` contains Reqcord's normalized representation of the captured API.

Markdown files are generated from that dataset.

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

Multiple examples for the same status code are also preserved.

For example:

```text
422 Unprocessable Entity
├── Email already exists
├── Name is required
└── Invalid phone number
```

Reqcord does not overwrite one `422` example with another.

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

Request and response body sanitization will follow the same principle.

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
  "method": "POST",
  "path": "/api/v2/customers",
  "request_examples": [
    {
      "headers": {
        "Authorization": "Bearer {{token}}"
      },
      "body": {
        "customer": {
          "name": "John Doe"
        }
      }
    }
  ],
  "response_examples": [
    {
      "name": "Created",
      "status": 201,
      "body": {
        "id": 42,
        "name": "John Doe"
      }
    },
    {
      "name": "Unauthorized",
      "status": 401,
      "body": {
        "error": "Unauthorized"
      }
    }
  ]
}
```

Every dataset contains a schema version so the internal format can evolve safely.

```json
{
  "schema_version": 1
}
```

## Architecture

```text
Reqcord
├── Configuration
├── Dataset
│   ├── Resource
│   ├── Endpoint
│   ├── RequestExample
│   └── ResponseExample
│
├── RouteCollector
│
├── TestAdapters
│   └── Minitest
│
├── Sanitizers
│   ├── Headers
│   ├── RequestBody
│   └── ResponseBody
│
├── Renderers
│   └── Curl
│
└── Exporters
    └── Markdown
```

Test adapters are responsible only for converting test execution into Reqcord's canonical model.

Exporters know nothing about Minitest or Rails test internals.

```text
Minitest ──┐
           │
RSpec ─────┼──► Dataset ──► Markdown
           │             ├─► OpenAPI
Other ─────┘             ├─► Postman
                         └─► ...
```

## v0.1 Scope

The first Reqcord release focuses on proving the capture pipeline.

### Included

* Rails 8
* Minitest integration/request tests
* Rails route discovery
* `reqcord.yml`
* Request capture
* Response capture
* Multiple response scenarios
* Sensitive data sanitization
* Canonical `dataset.json`
* Markdown documentation
* Generated cURL requests
* Resource filtering
* API version filtering

### Not included yet

* RSpec adapter
* OpenAPI generation
* Scalar integration
* Postman collections
* Hoppscotch collections
* Multipart requests
* Advanced schema inference
* CI documentation drift detection

These features belong to later releases rather than expanding the initial scope.

## Roadmap

### v0.2

OpenAPI 3.1 export and Scalar integration.

```text
Reqcord Dataset
      ↓
OpenAPI 3.1
      ↓
Scalar
```

This will allow a development application to expose documentation such as:

```text
http://localhost:3000/api-docs
```

### v0.3

RSpec request spec adapter.

Both test frameworks will produce the exact same Reqcord dataset:

```text
Minitest ─┐
          ├──► Reqcord Dataset
RSpec ────┘
```

### Future

Potential exporters and integrations include:

* Postman
* Hoppscotch
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

> Capture real Rails API requests and responses from Minitest and generate accurate, sanitized Markdown documentation with executable cURL examples.

Once that pipeline is reliable, additional adapters and exporters can be built on top of the same dataset.

## License

Reqcord is available as open source under the terms of the MIT License.
