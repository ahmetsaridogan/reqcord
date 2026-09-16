# Troubleshooting

The generate report is the first place to look; it says how many requests
were captured, how many matched a route, and where every route ended up.

```text
[reqcord] captured 87 request(s), 85 matched a documented route
[reqcord] captured a successful 2xx request for 15 of 16 endpoint(s)
[reqcord] routes: 18 = 15 documented + 1 uncovered + 2 skipped
```

## `no request was captured`

Nothing reached the capture file. In order of likelihood:

1. **The gem is not loaded in the test process.** It must be in the `:test`
   group of the Gemfile, not only `:development`.
2. **The run did not include the API tests.** `test.paths` (or
   `test.command`) points somewhere else. Name the directories that hold the
   integration tests / request specs:
   ```yaml
   test:
     paths:
       - test/integration
       - test/controllers/api
   ```
3. **The tests are not integration tests.** Reqcord patches
   `ActionDispatch::Integration::Session`; unit tests and controller tests
   that stub the request never go through it.
4. **The framework is wrong.** `test.framework: rspec` for request specs, or
   the examples are not named and the runner is not `rspec`.

## Many requests captured, few matched a route

`routes.prefix` does not cover them. The report prints the first unmatched
paths:

```text
[reqcord] 12 path(s) matched no documented route, for example:
[reqcord]   /v1/customers
```

Widen the prefix or give a list (`prefix: [/api, /v1]`). `bin/rails
reqcord:routes` shows what the current prefix documents.

## Routes documented, few covered

An endpoint is *documented* only when a test got a `2xx` from it. Routes that
tests reach only with `401`/`422` stay uncovered — add a happy-path test, or
check that the test which does succeed is under `test.paths`.

## The suite is red

By default Reqcord still writes the documentation and warns:

```text
[reqcord] test run exited with status 1; documenting what it captured anyway
[reqcord] the test run failed: routes exercised only by failing tests are listed as uncovered
```

A failed assertion after a `2xx` still counts as a documented request. If you
would rather get nothing from a red build, set `test.strict: true` (or
`REQCORD_STRICT=1`); the run then aborts with `Reqcord::GenerationError`.

## `unknown exporter "…"`

The `exporters:` list is used exactly as written (lists are not merged with
the defaults). Valid names: `curl`, `markdown`, `postman`, `openapi`.

## The cURL does not run

* `{{token}}`, `{{base_url}}` and other placeholders are meant to be replaced
  before running — they are the documentation's variables.
* The host is `variables.base_url` (`REQCORD_BASE_URL` per run).
* The command replays the request a test made; if the test relied on
  fixtures (an `id` that exists only in the test database) the real server
  needs equivalent data.

## `/api-docs` shows "No documentation generated yet"

`Reqcord::Web` only serves files; run `bin/rails reqcord:generate` first. If
you generated into a different directory (`REQCORD_OUTPUT`), mount
`Reqcord::Web.new(root: …)` for that directory, see [web.md](web.md).

## A value is listed as a closed set, or is not

The rules are in [capture.md → Inference](capture.md#inference): 2–6 distinct
values, not an identifier, and either repeated across requests or every value
a token. Free-text and generated values (`e-00056197`) are shown as one
example on purpose.

## A route is missing entirely

* `redirect(...)` routes and plain Rack mounts are *skipped*, and counted as
  such in the report.
* Rails' internal routes are always left out.
* Engine routes are walked under their mount path; the prefix filter sees
  the full path (`/api/billing/invoices`).
