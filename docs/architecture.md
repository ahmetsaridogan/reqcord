# Architecture

Reqcord separates **capturing API behaviour** from **rendering
documentation**. Test execution produces a framework-independent dataset;
exporters operate on that dataset and nothing else.

```text
                  Rails Routes
                       │
                       ▼
                Route Collector ─────────────────────────────┐
                       │                                     │
Minitest ──────► Test Adapter ──► Capture file (NDJSON)      │
RSpec    ──────►       │                                     │
                       ▼                                     │
                   Sanitizer                                 │
                       │                                     │
                       ▼                                     ▼
                Reqcord Dataset  ◄──── uncovered routes, skipped counts
                       │
          ┌────────────┼────────────┬────────────┐
          ▼            ▼            ▼            ▼
      Markdown       cURL        Postman      OpenAPI ──► Scalar (Reqcord::Web)
```

## Modules

```text
Reqcord
├── Configuration        reqcord.yml + ENV, defaults, deep merge
├── RouteCollector       every route kind, engines walked, skips counted by reason
│
├── Capture
│   ├── IntegrationPatch prepended to ActionDispatch::Integration::Session#process
│   ├── Collector        appends one NDJSON line per exchange, flock'd
│   ├── TestContext      thread-local "which test is running"
│   └── MinitestContext / RSpecContext
│
├── Sanitizers::Sanitizer  headers and bodies, before the dataset
│
├── Dataset
│   ├── Resource         one controller path → directory / folder / tag
│   ├── Endpoint         route + examples + inferred schemas + responses
│   ├── RequestExample / ResponseExample
│   └── Schema           fields, types, required, closed value sets
│
├── Generator            validate → collect routes → run tests → read captures
│                        → build dataset → report → write outputs
├── Check                generate into a scratch dir, diff against the committed docs
├── FileValue            the upload marker ({"$file": name, "content_type": type})
│
├── Renderers
│   ├── Payload          JSON vs form, nested query flattening (shared by cURL and Postman)
│   └── Curl
│
├── Exporters            registry: register("name", Klass)
│   ├── Markdown
│   ├── Curl
│   ├── Postman
│   └── Openapi
│
├── Web                  Rack app: Scalar page + generated files
└── Railtie              rake tasks; installs the patch only when capture is on
```

## The pipeline, step by step

1. **Validate** — framework and exporter names are checked before anything
   runs.
2. **Collect routes** — the route table is walked (mounted engines
   recursively, with their mount prefix), filtered by `routes.prefix`,
   `RESOURCE` and `VERSION`; redirects and Rack mounts are counted as
   skipped; multi-verb routes become one route per verb.
3. **Run the tests** — `test.command` or the runner built from `test.paths`,
   in a subprocess with `REQCORD_CAPTURE=1` and a capture file path. Inside
   the test process the Railtie prepends the integration patch and installs
   the framework context, so each request becomes one exchange line. Output
   is streamed. A red suite is a warning unless `test.strict`.
4. **Read and sanitize** — each line is parsed, malformed lines are skipped
   with a warning, and the sanitizer replaces credentials before anything is
   kept.
5. **Build the dataset** — exchanges are matched to routes; `via: :all`
   routes are materialized per captured verb; PATCH/PUT twins fold; examples
   dedupe by sanitized signature + status; schemas are inferred from accepted
   requests.
6. **Report** — `routes = documented + uncovered + skipped`, unmatched paths,
   the test outcome.
7. **Write** — `dataset.json`, then every configured exporter.

## Design principles

**Tests are the source of truth.** Reqcord observes existing tests instead
of asking for a documentation DSL. It never reads models, serializers or
contracts: what the application accepted and answered is the specification.

**Capture once, export anywhere.** Adapters turn test execution into the
canonical dataset; exporters know nothing about Minitest, RSpec or Rails
internals. A new format is one class with `call(dataset:, output_dir:,
configuration:)`.

**Nothing is lost silently.** Every route lands in one bucket and the report
reconciles the sum; unmatched captures are printed; malformed capture lines
are warned about.

**Generated documentation must be safe.** Sanitization runs before the
dataset exists, so `dataset.json` is as clean as the pages built from it.

**Useful without a server.** Markdown and cURL read fine on GitHub or in a
checkout; `Reqcord::Web` is optional.

## Scope

Included today: Rails 7.1–8.1 on Ruby 3.2+, Minitest integration tests and
RSpec request specs, the whole route table, JSON, form and multipart bodies,
multiple responses per endpoint, sanitization, inferred parameter and
response schemas, deterministic output, Markdown, cURL, Postman (Hoppscotch),
OpenAPI 3.1 and Scalar, `reqcord:check` for CI.

Not yet: capture outside Rails (Rack::Test for Sinatra, Roda, Hanami).
Candidate exporters: Bruno, Insomnia, `llms.txt`, static HTML, JSON Schema.

## Working on Reqcord

```bash
bundle install
bundle exec rake test                        # 190+ tests, ~12 s
BUNDLE_GEMFILE=gemfiles/rails_7.1.gemfile bundle exec rake test
```

The suite includes an out-of-process run of `test/dummy` (a small Rails app
with every route kind), a live Puma replay of every generated cURL script and
Postman request, Postman schema validation, and generation of the four
[`examples/`](../examples) — whose committed `docs/api` must match what the
code produces.
