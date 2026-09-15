# complex-spec-app (RSpec)

The store API of [complex-test-app](../complex-test-app), documented from
RSpec request specs instead of Minitest. The application file is identical;
only the specs differ, and the generated dataset lists the same 22 endpoints.

```text
app.rb                  the application (same as complex-test-app)
spec/requests/*_spec.rb ordinary request specs
spec/spec_helper.rb     request helpers for plain rspec-core (see spec-app)
reqcord.yml             `test.framework: rspec`, `paths: [spec/requests]`
docs/api/               generated Markdown, cURL scripts, Postman collection
```

## Regenerate

```bash
ruby generate.rb
```

See the endpoint tour in the [complex-test-app README](../complex-test-app/README.md).
