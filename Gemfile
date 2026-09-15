# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# activesupport 8.1.3.1 calls JSON.parse(json, options), a signature json 3.0
# dropped, so every JSON request body fails to parse with a 400. Development
# only: the gemspec leaves json to the host application and to Rails.
gem "json", "< 3"
