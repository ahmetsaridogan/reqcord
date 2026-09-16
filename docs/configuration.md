# `reqcord.yml` reference

Reqcord reads one file, `reqcord.yml`, from the application root (`Rails.root`).
`bin/rails reqcord:init` writes a starting point; every key is optional.

```yaml
version: 1

test:
  framework: minitest
  paths:
    - test/integration
    - test/api

routes:
  prefix: /api

output:
  directory: docs/api
  include_uncovered: false

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
    X-Api-Key: "{{api_key}}"
  body:
    password: "{{password}}"
```

## How values are resolved

```text
environment variable  >  reqcord.yml  >  Reqcord default
```

The file is **deep-merged** over the defaults: setting `sanitize.headers.X-Account-Id`
keeps the default `Authorization` and `X-Api-Key` entries. Lists are replaced,
not merged: an `exporters:` list is used exactly as written.

The file must be a YAML mapping; anything else raises `Reqcord::ConfigurationError`
before any test runs. YAML aliases are disabled.

| Variable | Overrides |
| --- | --- |
| `REQCORD_TEST_FRAMEWORK` | `test.framework` |
| `REQCORD_TEST_COMMAND` | `test.command` (and therefore `test.paths`) |
| `REQCORD_STRICT` | `test.strict` (`1` or `true`) |
| `REQCORD_OUTPUT` | `output.directory` |
| `REQCORD_BASE_URL` | `variables.base_url` |
| `RESOURCE`, `VERSION` | run-time filters, see [Filtering a run](#filtering-a-run) |

`REQCORD_CAPTURE` and `REQCORD_CAPTURE_FILE` are set **by** Reqcord on the test
process it starts; do not set them yourself. Without them an ordinary
`bin/rails test` patches nothing and writes nothing.

---

## `version`

```yaml
version: 1
```

The configuration format version. Informational today; keep it at `1`.

---

## `test`

Where the requests come from. `reqcord:generate` runs your suite in a
subprocess with capture enabled; every request the integration tests make
is captured, so point this at the tests that exercise the API.

### `test.framework`

`minitest` (default) or `rspec`. Decides two things: how the suite is run
when only `paths` is given, and how captured examples are named — from the
Minitest test method (`test "creates customer"`) or the RSpec example
(`it "creates customer"`). Any other value is rejected before the run.

### `test.paths`

Directories, files or globs. Reqcord builds the runner:

| Framework | Project has `bin/rails` | Command |
| --- | --- | --- |
| minitest | yes | `bin/rails test <paths…>` |
| minitest | no | `ruby -Itest -e '<require each file>' <every *_test.rb beneath the paths>` |
| rspec | — | `rspec <paths…>` |

A directory means every `*_test.rb` (or `*_spec.rb`) beneath it; a glob such as
`test/api/*_test.rb` is expanded by Reqcord.

```yaml
test:
  framework: minitest
  paths:
    - test/api
    - test/controllers/api
    - test/integration
```

### `test.command`

Spell the command out yourself. It wins over `paths`.

```yaml
test:
  command: bin/rails test test/api test/integration/orders_test.rb
```

The command is split into words and executed **without a shell**: no pipes,
`&&`, environment assignments or quoting tricks. Globs in the arguments are
expanded by Reqcord (`test/api/*_test.rb` works). An empty string counts as
absent.

With neither `paths` nor `command`, Reqcord runs `bin/rails test`.

### `test.strict`

Default `false`. What happens when the suite does not exit successfully:

* `false` — the run continues and documents what the tests captured. A
  warning names the exit status, and the report reminds you that routes
  exercised only by failing tests show up as *uncovered*. A test that failed
  on an assertion after its request got a `2xx` still counts: the request
  and response are what the application really did.
* `true` (or `REQCORD_STRICT=1`) — a failing suite aborts the run with
  `Reqcord::GenerationError` and nothing is written. Use it in CI when the
  generated docs are an artifact that must come from a green build.

```yaml
test:
  strict: true
```

---

## `routes`

The documented surface is the application's route table (including mounted
engines), not the captured traffic: every matching route becomes an endpoint,
and captures are attached to it.

### `routes.prefix`

Default `/api`. Only routes whose path starts with the prefix are documented.
For a mounted engine the prefix is matched against the full path
(`/api/billing/invoices`). Set it to an empty string to document every route.

```yaml
routes:
  prefix: /api/v2
```

A list documents routes under any of the prefixes — for APIs whose versions
or audiences do not share a root:

```yaml
routes:
  prefix:
    - /v1
    - /v2
    - /partner
```

One prefix already covers every version beneath it (`/api` includes `/api/v1`
and `/api/v2`); use `VERSION=v2` to generate for one of them.

Rails' own routes (`rails/…`, Active Storage, Action Mailbox, Turbo) are always
left out. `redirect(...)` routes and plain Rack mounts cannot be documented from
a test; they are counted as *skipped* in the report rather than dropped.

### Filtering a run

Filters are given per run, not in the file:

```bash
bin/rails reqcord:generate RESOURCE=customers
bin/rails reqcord:generate RESOURCE=customers,cart
bin/rails reqcord:generate VERSION=v2
bin/rails reqcord:generate RESOURCE=orders VERSION=v1
```

`RESOURCE` matches the controller's last segment (`customers`), its singular
(`cart` for `CartsController`) or the full controller path
(`api/v2/customers`). `VERSION` matches a `v<number>` segment in the controller
path or the route path.

---

## `output`

### `output.directory`

Default `docs/api`, relative to the application root (an absolute path is used
as is). Override per run with `REQCORD_OUTPUT`. A run writes:

```text
<directory>/
├── dataset.json          the canonical dataset every exporter reads
├── README.md             index of resources and endpoints        (markdown)
├── api/v1/customers/     one directory per controller path       (markdown)
│   ├── index.md
│   └── create.md
├── curl/api/v1/customers/create.sh                                 (curl)
├── postman/collection.json                                         (postman)
└── openapi/openapi.json                                            (openapi)
```

Directories follow the controller path, so `admin/customers` and
`api/v1/customers` never collide.

### `output.include_uncovered`

Default `false`. A route no test reached with a `2xx` response is listed in
the index under *No Successful Request Captured* and in `dataset.json` under
`uncovered_routes`, but gets no page of its own. Set `true` to write those
pages as well, each carrying a note that nothing was captured.

---

## `exporters`

Which outputs to write. Default: all four.

| Name | Writes |
| --- | --- |
| `markdown` | `README.md` plus one page per endpoint: headers, typed parameter tables, example request, cURL, one example and field table per response status |
| `curl` | one runnable `.sh` per endpoint under `curl/`, built from the successful captured request |
| `postman` | `postman/collection.json`, a Postman Collection v2.1 — folders per controller namespace, one request per endpoint, every captured status saved as an example, placeholders as collection variables, bearer auth at collection level. Hoppscotch imports the same file |
| `openapi` | `openapi/openapi.json`, an OpenAPI 3.1 document — one path item per documented route (`/items(/:id)` becomes `/items` and `/items/{id}`), parameters and request body schemas rebuilt from the inferred fields, one response per captured status with schema and example, `bearerAuth` / `apiKeyAuth` security schemes from the sanitized headers. `servers` comes from `variables.base_url` |

`dataset.json` is always written. An unknown name raises
`Reqcord::ConfigurationError` before any test runs.

### Browsing the output: `Reqcord::Web`

The generated directory can be served from the application itself:

```ruby
# config/routes.rb
mount Reqcord::Web => "/api-docs" if Rails.env.development?
```

`/api-docs` renders the OpenAPI document with Scalar (loaded from
`cdn.jsdelivr.net`); every other path under the mount is a file from
`output.directory` — `openapi/openapi.json`, `dataset.json`,
`postman/collection.json`, the Markdown pages, the cURL scripts. Requests
that resolve outside that directory get a `404`. Nothing is generated on the
fly: run `bin/rails reqcord:generate` first, and again after the tests change.

`Reqcord::Web` reads `output.directory` from `reqcord.yml` (and
`REQCORD_OUTPUT`). To serve a different directory, mount an instance instead:

```ruby
mount Reqcord::Web.new(root: Rails.root.join("public/api-docs")) => "/api-docs"
```

---

## `variables`

### `variables.base_url`

Default `http://localhost:3000`. The host in every generated cURL and the value
of the Postman `base_url` collection variable. A trailing slash is dropped.
Override per run with `REQCORD_BASE_URL`.

Other keys under `variables` are read but not used by the built-in exporters.

---

## `sanitize`

Captured tests carry real credentials. Sanitization runs on every exchange
before anything reaches the dataset, so generated files never contain them.

### `sanitize.headers`

Header name → replacement, matched case-insensitively, replaced **verbatim**:

```yaml
sanitize:
  headers:
    Authorization: "Bearer {{token}}"
    X-Api-Key: "{{api_key}}"
    X-Account-Id: "{{account_id}}"
```

Defaults: `Authorization: "Bearer {{token}}"` and `X-Api-Key: "{{api_key}}"`.

Some headers are redacted **whether configured or not**: `Authorization`,
`Proxy-Authorization`, `Cookie`, `Set-Cookie`, `X-Api-Key`, `X-Auth-Token`,
`X-Csrf-Token`. Without a configured replacement the value becomes a
placeholder named after the header (`{{cookie}}`, `{{x_auth_token}}`), and a
`Bearer`, `Token` or `Basic` scheme is kept so the cURL stays runnable
(`Basic {{authorization}}`).

Two more things happen to headers, on requests and responses alike:

* transport noise is dropped: `Host`, `User-Agent`, `Connection`, `Version`,
  `Remote-Addr`, `Accept-Encoding`, `Cache-Control`, `Content-Length`, `Date`,
  `ETag`, `Server-Timing`, `Transfer-Encoding`, `Vary`, `X-Request-Id`,
  `X-Runtime`, `Referrer-Policy` and the `X-*-Options` security headers;
* headers with an empty value are dropped.

### `sanitize.body`

Body key → replacement, matched case-insensitively **at any depth**, in
request and response bodies alike. The whole value under the key is replaced,
whatever its type.

```yaml
sanitize:
  body:
    password: "{{password}}"
    payment_url: "{{payment_url}}"
```

Defaults: `password`, `password_confirmation`, `token`, `access_token`,
`refresh_token`, `api_key`, `secret`, `client_secret` (→ `{{password}}`,
`{{token}}`, `{{api_key}}`, `{{secret}}`).

A sanitized value is what the documentation shows, so it also shapes the
parameter tables: two logins whose passwords both became `{{password}}` are two
examples of the same request, and the one that succeeded is the one used for
the cURL.

### Placeholders

Every `{{name}}` you write is kept as-is in Markdown and cURL, listed in the
index under *Placeholders*, and declared as a variable in the Postman
collection — Postman's variable syntax is the same, so the collection runs as
soon as `base_url` and `token` are filled in.

---

## Rake tasks

| Task | Does |
| --- | --- |
| `bin/rails reqcord:init` | writes `reqcord.yml` (never overwrites) and creates `docs/api/` |
| `bin/rails reqcord:generate` | collects routes, runs the suite with capture, writes every exporter, prints the report |
| `bin/rails reqcord:check` | generates into a scratch directory and compares with `output.directory`; exits 1 with an `A`/`D`/`M` file list when the committed docs are behind the tests. Honours `RESOURCE` / `VERSION` |
| `bin/rails reqcord:routes` | lists the routes the current `prefix` (and `RESOURCE` / `VERSION`) would document |

Every `generate` run ends with a reconciliation of the whole route table:

```text
[reqcord] captured 92 request(s), 87 matched a documented route
[reqcord] captured a successful 2xx request for 14 of 16 endpoint(s)
[reqcord] routes: 16 = 14 documented + 2 uncovered + 0 skipped
```

Each route is in exactly one bucket; a captured request that matched no
documented route is listed, never dropped silently.

## When the output looks thin

| Symptom | Usual cause |
| --- | --- |
| `no request was captured` | the gem is not in the `:test` group of the Gemfile, or `test.paths` / `test.command` runs no integration tests |
| many requests captured, few matched | `routes.prefix` does not cover them — the unmatched paths are printed |
| routes documented but few covered | the tests that exercise them are not in `test.paths` (a `2xx` from a test is what makes an endpoint documented) |
| `test run exited with status …` | the suite is red; the docs were still generated from what it captured. `test.strict: true` aborts instead |

More in [troubleshooting.md](troubleshooting.md).
