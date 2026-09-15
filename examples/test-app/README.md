# test-app (Minitest)

A one file Rails API with ordinary Minitest integration tests, and the
documentation Reqcord generates from them. Three resources, each there to
show something different in the output:

| Resource | Shows |
| --- | --- |
| `customers` | bearer auth, a closed set of values (`"active" \| "passive"`), 401/422 responses |
| `users` | a second authenticated resource with its own status set |
| `tasks` | no auth, full CRUD, `PATCH` and `PUT` folded into one page, a `204`, a member action (`complete`), a filtered index (`?status=open`) |

```text
app.rb                              the application
test/integration/*_test.rb          ordinary integration tests
reqcord.yml                         Reqcord configuration
docs/api/                           generated output, committed here so you can
                                    read it without running anything:
  api/v1/{customers,users,tasks}/*.md Markdown, one page per endpoint
  curl/api/v1/**/*.sh                 runnable cURL scripts
  postman/collection.json             Postman collection (Hoppscotch imports it)
  dataset.json                        the canonical dataset behind all three
```

## Regenerate

```bash
ruby generate.rb
```

In a real application you would run `bin/rails reqcord:generate` instead;
`generate.rb` only exists because this example has no `bin/rails`.

`reqcord.yml` only names the test directory; with no `bin/rails` around,
Reqcord runs every `*_test.rb` beneath it itself.

Filters work the same way:

```bash
RESOURCE=tasks ruby generate.rb
RESOURCE=customers,users ruby generate.rb
VERSION=v1 ruby generate.rb
```

## What to look at

- The tests never mention Reqcord.
- `Authorization: Bearer eyJ...` is written as `Bearer {{token}}` in
  [docs/api/api/v1/customers/create.md](docs/api/api/v1/customers/create.md).
- `customer.status` is documented as `"active" | "passive"`: two tests sent
  those and passed, a third sent `"inactive"` and was rejected, so the
  rejected value never becomes a documented parameter.
- One endpoint carries every status its tests produced: `201`, `422`, `401`.
- Each cURL example uses the real captured path, so it can be pasted into a
  terminal once `{{token}}` is replaced; the same request is in
  [docs/api/postman/collection.json](docs/api/postman/collection.json) with
  `{{token}}` as a collection variable.
