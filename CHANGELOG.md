# Changelog

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
* Rails 7.1 and 7.2 are supported alongside 8.x (Ruby 3.2+); CI runs every
  supported Ruby × Rails pair through `gemfiles/`.

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
