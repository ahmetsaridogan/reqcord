# frozen_string_literal: true

module Reqcord
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path(
        "../tasks/reqcord.rake",
        __dir__
      )
    end

    initializer "reqcord.capture" do
      next unless Reqcord::Capture.enabled?

      require "action_dispatch/testing/integration"
      require_relative "capture/integration_patch"

      unless ActionDispatch::Integration::Session <
             Reqcord::Capture::IntegrationPatch

        ActionDispatch::Integration::Session.prepend(
          Reqcord::Capture::IntegrationPatch
        )
      end

      # Capture itself is framework agnostic; only naming the example needs to
      # know which test framework is running.
      case Reqcord.configuration.test_framework.to_s
      when "minitest"
        require "minitest/test"
        require_relative "capture/minitest_context"

        unless Minitest::Test < Reqcord::Capture::MinitestContext
          Minitest::Test.prepend(
            Reqcord::Capture::MinitestContext
          )
        end

      when "rspec"
        require "rspec/core"
        require_relative "capture/rspec_context"

        Reqcord::Capture::RSpecContext.install!

      else
        raise ConfigurationError,
              "unsupported test framework: #{Reqcord.configuration.test_framework.inspect}"
      end
    end
  end
end
