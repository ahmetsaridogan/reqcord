# frozen_string_literal: true

require_relative "../app"

require "rspec/core"
require "action_dispatch/testing/integration"

RSpec.configure do |config|
  # What rspec-rails would give you as `type: :request`; spelled out here so
  # the example runs with plain rspec-core.
  config.include ActionDispatch::Integration::Runner, type: :request
  config.include ActionDispatch::IntegrationTest::Behavior, type: :request

  config.before(:each, type: :request) { integration_session }

  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
end
