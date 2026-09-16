# Reqcord::Web

`Reqcord::Web` is a Rack application that serves the generated documentation
from inside the Rails app, the way `Sidekiq::Web` does. It renders the
OpenAPI document with [Scalar](https://scalar.com) and serves every other
generated file.

## Mount it

```ruby
# config/routes.rb
mount Reqcord::Web => "/api-docs" if Rails.env.development?
```

Then `bin/rails reqcord:generate` and open `http://localhost:3000/api-docs`.

## What it serves

| Path | Content |
| --- | --- |
| `/api-docs` | the Scalar reference for `openapi/openapi.json` — searchable, with a *Try it* client |
| `/api-docs/openapi/openapi.json` | the OpenAPI document |
| `/api-docs/dataset.json` | the canonical dataset |
| `/api-docs/postman/collection.json` | the Postman collection |
| `/api-docs/README.md`, `/api-docs/api/v2/customers/create.md` … | the Markdown pages (`text/markdown`) |
| `/api-docs/curl/api/v2/customers/create.sh` | the cURL scripts (`text/plain`) |

The mount point can be anything; the page computes its links from it.

Before the first generate, `/api-docs` shows a page saying what to run.

## Rules

* **Read-only.** Nothing is generated on request. Run `reqcord:generate`
  after the tests change; the page picks up the new files on reload.
* **Only the output directory.** Every request is resolved inside
  `output.directory`; a path that escapes it (`..`, encoded or not) is a
  `404`, as is anything that is not a regular file.
* **Scalar comes from a CDN.** The page loads
  `https://cdn.jsdelivr.net/npm/@scalar/api-reference`. With a strict
  Content-Security-Policy, allow that host for `script-src`.

## Serving a different directory

`Reqcord::Web` reads `output.directory` from `reqcord.yml` (and
`REQCORD_OUTPUT`). To serve another directory, mount an instance:

```ruby
mount Reqcord::Web.new(root: Rails.root.join("public/api-docs")) => "/api-docs"
```

## Production

The files are static and contain only sanitized data, so mounting in
production is a deployment decision rather than a Reqcord one. Guard the
route like any internal page:

```ruby
authenticate :admin do
  mount Reqcord::Web => "/api-docs"
end
```

or leave the mount behind `Rails.env.development?` and publish the generated
`docs/api` directory (or the OpenAPI file alone) through whatever already
hosts your documentation.
