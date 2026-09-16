# Changelog

## [0.3.0] - Unreleased

### Added

* Multipart uploads are documented. A `Rack::Test::UploadedFile` in a test's
  params becomes a `file` field (shown by name, `label.png`), `--form
  image=@label.png;type=image/png` in cURL, a `formdata` file part in Postman
  and `type: string, format: binary` under `multipart/form-data` in OpenAPI.
  The bytes never reach the dataset.
* `bin/rails reqcord:check` (`Reqcord::Check`): regenerates into a scratch
  directory and compares with the committed output, file by file; exits 1
  with a git-status style list when the docs are behind the tests — the CI
  guard for documentation drift.

### Changed

* Output is deterministic. Captured exchanges are ordered by test file, line
  and name before the dataset is built, so "the first example" no longer
  depends on the test run order, and `dataset.json` no longer carries a
  `generated_at` timestamp. Regenerating without a code change produces no
  diff.

### Fixed

* `routes.prefix` matches whole path segments: `/api` no longer swallows
  `/api-docs` (which made a mounted `Reqcord::Web` show up as a skipped
  route).

## [0.2.0] - 2026-09-16

### Added

* OpenAPI 3.1 exporter (`openapi/openapi.json`, on by default): one path item
  per documented route (`/items(/:id)` becomes `/items` and `/items/{id}`),
  parameters and request bodies from the inferred schemas, one response per
  captured status with its example, bearer / API-key security schemes from
  the sanitized headers.
* `Reqcord::Web`: `mount Reqcord::Web => "/api-docs"` serves the OpenAPI
  document with Scalar and every other generated file (`dataset.json`, the
  Postman collection, Markdown pages, cURL scripts) from inside the
  application, Sidekiq::Web style.

## [0.1.4] - 2026-09-16

### Changed

* A failing test run no longer discards the output. The docs are generated
  from what the suite captured, the warning names the exit status and the
  report points out that routes reached only by failing tests are listed as
  uncovered. The previous behaviour is `test.strict: true`.

### Added

* `test.strict` (`REQCORD_STRICT=1`): abort on a failing suite instead of
  documenting what it captured.

## [0.1.3] - 2026-09-16

### Added

* `routes.prefix` accepts a list (`[/v1, /v2, /partner]`) for APIs whose
  versions or audiences do not share a root.

### Changed

* The `reqcord:init` template now names test directories (`test.paths`)
  instead of running the whole suite, and documents every key inline.

## [0.1.2] - 2026-09-16

### Added

* Rails 7.1 and 7.2 are supported alongside 8.x (Ruby 3.2+); CI runs every
  supported Ruby × Rails pair through `gemfiles/`.

### Fixed

* CI resolves the bundle per Ruby (no committed `Gemfile.lock`) and pins
  `json < 3` for development: activesupport 8.1 calls `JSON.parse(json,
  options)`, a signature json 3.0 dropped.

## [0.1.1] - 2026-09-15

### Added

* Postman Collection v2.1 exporter (`postman/collection.json`), on by default.
  Folders follow controller namespaces, requests come from the successful
  captured example, every captured status is a saved response, sanitizer
  placeholders become collection variables and `Bearer {{token}}` becomes
  collection-level auth. Hoppscotch imports the same file.
* Request parameters (`parameters.path/query/body`) and response fields
  (`responses[].schema`) inferred per endpoint from accepted requests, written
  to `dataset.json` (`schema_version: 2`) and rendered as typed tables in
  Markdown, with closed value sets listed (`"active" | "passive"`).
* Full route table coverage: `match … via: [:get, :post]` becomes one endpoint
  per verb, `via: :all` is documented per verb the tests used, mounted engines
  are walked under their mount path, `resource :cart` and `root` are titled
  sensibly, optional segments and globs are path parameters.
* PATCH/PUT twins of `update` fold into one endpoint (`also_methods`).
* Resources are grouped by full controller path, so `admin/customers` and
  `api/v2/customers` get separate directories and Postman folders.
* The run reconciles the route table:
  `routes = documented + uncovered + skipped`, with redirects and Rack mounts
  counted as skipped instead of vanishing.
* `RESOURCE=` accepts the singular (`cart`) and the controller path.
* `route_name` (the `as:` name) is kept in the dataset.
* `Renderers::Payload`: the JSON/form and query-flattening decisions shared by
  cURL and Postman.
* `test.paths`: name the directories (or files, or globs) the API tests live
  in and Reqcord picks the runner — `bin/rails test`, `rspec`, or a plain Ruby
  runner when the project has no `bin/rails`. `test.command` still wins when
  given, and its globs now expand.
* Three-resource examples (`customers`, `users`, `tasks`) in both
  `examples/test-app` and `examples/spec-app`.

### Changed

* Canonical cURL comes only from captured 2xx requests; error-case payloads
  stay as response examples.
* Endpoint Markdown/cURL files are written only when a successful request was
  captured; uncovered routes are listed under `uncovered_routes` and in the
  index.
* Form bodies render as `--data 'a=b'` / `urlencoded`, never re-invented as
  JSON.
* `reqcord:init` defaults `test.command` to `bin/rails test`.

### Fixed

* `Endpoint#add_exchange` records the response status on the request, so the
  public API produces documented endpoints without extra setup.
* `RequestExample.from_h` / `ResponseExample.from_h` ignore keys written by a
  newer Reqcord.
* A request that produced a different status is kept as its own example even
  when sanitization makes it read like an earlier one (a right and a wrong
  password both become `{{password}}`), so test order can no longer decide
  whether a login endpoint counts as covered.
* A parameter is only `required` when every accepted request carried it; a
  request accepted with no parameters at all now counts, so `?status=` on a
  list endpoint is documented as optional.
* Response fields list a closed set of values only when the values look like
  tokens (`"open" | "done"`); fixture names and SKUs that merely repeat across
  responses are shown as one example.

## [0.1.0]

* RSpec request spec support (`test.framework: rspec`)
* Runnable Minitest and RSpec examples under `examples/`
* Minitest integration test capture for Rails 8, written to a lockable
  capture file so parallel test workers can share it
* Rails route discovery and endpoint grouping
* `reqcord.yml` configuration
* Header and body sanitization
* Canonical `dataset.json`
* Markdown documentation with generated cURL examples
* Resource and API version filtering
* Routes with no captured example are reported as documentation gaps
