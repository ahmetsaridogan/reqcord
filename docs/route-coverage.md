# Route coverage

The documented surface is the application's **route table**, not the traffic
the tests happened to produce. Every route under `routes.prefix` becomes an
endpoint; captured requests are attached to it. That is what lets the run end
with an accounting nothing can slip through:

```text
routes = documented + uncovered + skipped
```

| Bucket | Rule |
| --- | --- |
| documented | at least one captured request returned a `2xx` |
| uncovered | no `2xx` was captured; the route is listed under *No Successful Request Captured* and in `dataset.json` → `uncovered_routes` |
| skipped | `redirect(...)` routes and plain Rack mounts: nothing a test could document; counted by reason in the report |

A captured request that matches no documented route is reported with its
path (the first five), never dropped silently — usually a sign that
`routes.prefix` is too narrow.

## What becomes an endpoint

| Route | Documented as |
| --- | --- |
| `resources :customers` | one endpoint per action; `index` is titled *List Customers*, `show` *Get Customer*, `create`, `update`, `destroy`, `new`, `edit` likewise |
| `post :activate, on: :member` | *Activate Customer* |
| `resource :cart` | `GET /cart` (*Get Cart*), `PATCH /cart` (also `PUT`) — one record, no id |
| `post "checkout", on: :collection` under `resource :cart` | *Checkout Cart* |
| `post "auth/login", to: "auth#login"` | *Login* — the action is the page, the controller only where it lives |
| `root to: "home#index"` | `GET /`, titled *Home* |
| `match "/echo", via: [:get, :post]` | `GET /echo` and `POST /echo`, two endpoints |
| `match "/anything", via: :all` | one endpoint per verb the tests actually used; one `ANY` entry when none did |
| `patch` + `put` for `update` | folded into one endpoint, `also_methods: ["PUT"]`; the captured verb wins, `PATCH` preferred |
| `get "/items(/:id)"` | one endpoint; the optional segment is kept in the path, `id` is a path parameter |
| `get "/files/*path"` | `path` as a path parameter |
| `resources :items, param: :sku` | `sku` as the path parameter |
| `namespace :admin { resources :customers }` | `admin/customers`, a separate resource from `api/v2/customers` |
| `mount Billing::Engine => "/billing"` | the engine's own routes, walked under `/billing`; the prefix filter sees the full path |
| `scope module: :v2` / `namespace :v2` | `v2` detected as the API version (`VERSION=v2` filters on it) |

Rails' own routes (`rails/…`, Active Storage, Action Mailbox, Turbo — anything
flagged `internal`) are always left out.

## Grouping

Endpoints are grouped by the **full controller path**: `api/v2/customers`,
`admin/customers`, `billing/invoices`. That path becomes the Markdown
directory, the Postman folder chain (`Api › V2 › Customers`) and the OpenAPI
tag, so two controllers with the same last segment never collide.

## Naming

Endpoint names come from the action and the resource, not from the test
names — tests name the *examples*. The table above shows the patterns; a
custom action on a plural resource is `<Action> <Resource>` (*Cancel Order*),
on a singular resource `<Action> <Singular>` (*Checkout Cart*), and a custom
action whose name is in the path of a singular controller is just the action
(*Login*).

## Filtering a run

```bash
bin/rails reqcord:generate RESOURCE=customers
bin/rails reqcord:generate RESOURCE=customers,cart
bin/rails reqcord:generate VERSION=v2
bin/rails reqcord:generate RESOURCE=orders VERSION=v1
```

`RESOURCE` matches the controller's last segment (`customers`), its singular
(`cart` for `CartsController`) or the full controller path
(`api/v2/customers`). `VERSION` matches a `v<number>` segment in the
controller path or the route path.

`bin/rails reqcord:routes` prints what the current prefix and filters would
document, without running any test.

## Prefixes

```yaml
routes:
  prefix: /api            # everything under /api, all versions
```

```yaml
routes:
  prefix: [/v1, /v2, /partner]   # APIs whose versions do not share a root
```

An empty prefix documents every route. For a mounted engine the prefix is
matched against the full path (`/api/billing/invoices`).
