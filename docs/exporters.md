# Exporters

Every exporter reads `dataset.json` and nothing else; none of them knows
about Minitest, RSpec or Rails. Pick them in `reqcord.yml`:

```yaml
exporters:
  - curl
  - markdown
  - postman
  - openapi
```

All four are on by default. `dataset.json` is always written. An unknown name
raises `Reqcord::ConfigurationError` before any test runs.

Only **documented** endpoints — those a test reached with a `2xx` — get a
Markdown page, a cURL script, a Postman request and an OpenAPI operation.
Uncovered routes are listed in the Markdown index and in
`dataset.json` (`uncovered_routes`); `output.include_uncovered: true` also
writes a placeholder page for each.

## What the canonical request is

Every output that shows a request — the cURL, the Postman request, the OpenAPI
example — uses the same one: the first captured request that returned a
`2xx`, with its concrete URL, headers, query and body, sanitized. Reqcord
never invents a payload. Requests that produced other statuses are kept as
response examples, never promoted to the canonical request.

## `markdown`

```text
docs/api/
├── README.md
├── api/v2/customers/
│   ├── index.md
│   ├── list.md
│   ├── create.md
│   ├── show.md
│   └── update.md
└── admin/customers/
    └── …
```

* **`README.md`** — the base URL, a *Placeholders* table (every sanitized
  header and its replacement), one section per resource with a
  method / path / description table linking to the endpoint pages, and a *No
  Successful Request Captured* section listing the uncovered routes.
* **`<controller path>/index.md`** — the resource's endpoints.
* **`<controller path>/<action>.md`** — the endpoint page: method and path
  (with `(also PUT)` when PATCH/PUT twins were folded), the namespace, the
  headers, *Path / Query / Body Parameters* tables (`Field | Type | Required |
  Values`), the example request, the cURL, and one `### <status>` section per
  captured status with a *Fields* table and an example body.

Directories follow the full controller path, so `admin/customers` and
`api/v2/customers` never collide. File names come from the action
(`index` → `list.md`); when two endpoints of a resource would share a name the
verb is appended.

Form bodies are shown as they were sent, with a note that the request is
`application/x-www-form-urlencoded`. In a multipart request a file part is
shown by name and type (`"image": "label.png (image/png)"`) and typed `file`
in the parameter table.

## `curl`

One runnable script per documented endpoint:

```text
docs/api/curl/api/v2/customers/create.sh
```

```bash
curl --request POST \
  --url "http://localhost:3000/api/v2/customers" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --data '{
  "customer": {
    "name": "John Doe",
    "email": "john@example.com",
    "status": "active"
  }
}'
```

* The host is `variables.base_url`.
* JSON bodies are `--data '<json>'`; form bodies are `--data 'a=b'` pairs,
  never re-encoded as JSON; query strings keep Rails' bracket notation
  (`filter[category]=mugs`).
* Uploads are one `--form` per part, the file as `@name`
  (`--form 'image=@label.png;type=image/png'`) — run the script from the
  directory that holds the file. curl sets the multipart `Content-Type` and
  boundary itself, so none is written.
* Placeholders (`{{token}}`) are left for you to substitute — the scripts
  are meant to be copied into a terminal or a runbook.

Reqcord's own test suite replays every generated script of its dummy
application against a live Puma and asserts the documented status, so the
scripts are known to run.

## `postman`

`docs/api/postman/collection.json`, a Postman Collection v2.1:

* one folder per controller namespace (`Api › V2 › Customers`),
* one request per documented endpoint, from the canonical request — JSON
  bodies as `raw`, form bodies as `urlencoded`, uploads as `formdata` with
  the file part's `src` set to the file name (pick the file in Postman),
* every captured status saved as a response example on that request,
* collection variables for `base_url` and every placeholder the sanitizer
  wrote (`{{token}}`, `{{api_key}}` …) — Postman's variable syntax is the
  same, so the collection runs as soon as the variables are filled in,
* `Authorization: Bearer {{token}}` lifted to collection-level bearer auth;
  requests made without credentials are marked `noauth`, so they replay
  exactly as their tests did.

The collection is validated against the published v2.1 JSON Schema in
Reqcord's tests, and replayed against the dummy application.

**Hoppscotch** imports Postman v2.1 collections directly: *Import → Postman*
and point it at the same file.

## `openapi`

`docs/api/openapi/openapi.json`, an OpenAPI 3.1 document:

* `info.title` is `<application directory> API`; `info.version` is the API
  version when the dataset has exactly one (`v2`), `1.0.0` otherwise;
  `servers` is `variables.base_url`.
* One path item per documented route in OpenAPI notation: `/customers/:id`
  → `/customers/{id}`, `/files/*path` → `/files/{path}`. An optional segment
  becomes two paths: `/items(/:id)` → `/items` and `/items/{id}`.
* One operation per verb: `operationId` from the verb and path
  (`post_api_v2_customers`), `summary` is the endpoint name, `tags` is the
  resource, `description` carries `controller#action`, the route name and
  the folded verbs.
* **Parameters**: path parameters (always required) and query parameters
  from the inferred schemas, with `enum` for closed value sets and the
  captured example. Nested query params keep Rails' bracket notation
  (`filter[status]`).
* **Request body**: `application/json`, `application/x-www-form-urlencoded`
  or `multipart/form-data`, whichever the test sent. The JSON Schema is
  rebuilt from the flattened field paths — `order.line_items[].sku` becomes
  object → array → object — with `required` at every level from what every
  accepted request carried, and the canonical request as `example`. A file
  part is `type: string, format: binary`, its example the file name.
* **Responses**: one per captured status, `description` from the status
  text, schema and example from the captured bodies.
* **Security**: `bearerAuth` (HTTP bearer) when a documented request carried
  `Authorization: Bearer …`, `apiKeyAuth` (header) for the first sanitized
  API-key header a request carried (`X-Api-Key` by default). Applied per
  operation, so endpoints called without credentials stay public.

Anything that reads OpenAPI consumes the file as is: Scalar (through
[`Reqcord::Web`](web.md)), Swagger UI, Redoc, client generators.

## Writing your own

An exporter is a class with one class method, registered under a name:

```ruby
module Reqcord
  module Exporters
    class Bruno
      def self.call(dataset:, output_dir:, configuration:)
        # dataset: Reqcord::Dataset — resources, endpoints, examples, schemas
        # returns the paths it wrote
      end
    end

    register("bruno", Bruno)
  end
end
```

Once registered, `exporters: [bruno]` in `reqcord.yml` runs it after the
tests. `dataset.json` on disk is the same structure, if you would rather
post-process the file from another language. See
[architecture.md](architecture.md) for the dataset.
