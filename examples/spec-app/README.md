# spec-app (RSpec)

The same API as [test-app](../test-app), documented from RSpec request specs
instead of Minitest. The generated dataset is identical in shape: the test
framework only decides how examples are named.

```text
app.rb                            the application (customers, users, tasks)
spec/requests/*_spec.rb           ordinary request specs
spec/spec_helper.rb               request helpers (see the note below)
reqcord.yml                       `test.framework: rspec`
docs/api/                         generated Markdown, cURL scripts and Postman
                                  collection — the same files test-app gets
```

## Regenerate

```bash
ruby generate.rb
```

## Notes

This example runs on plain `rspec-core`, so `spec_helper.rb` includes the
ActionDispatch request helpers itself and the specs assert
`response.status`. An application using `rspec-rails` gets `type: :request`
and `have_http_status` for free and needs none of that.

The only Reqcord-facing difference from test-app is one line in `reqcord.yml`:

```yaml
test:
  framework: rspec
  paths:
    - spec/requests
```
