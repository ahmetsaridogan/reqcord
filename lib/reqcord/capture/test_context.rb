# frozen_string_literal: true

module Reqcord
  module Capture
    # The test that is currently running, kept per thread so parallel runners
    # do not attribute an exchange to the wrong test.
    module TestContext
      THREAD_KEY = :reqcord_test_context

      class << self
        def current
          Thread.current[THREAD_KEY] || {}
        end

        def current=(value)
          Thread.current[THREAD_KEY] = value
        end

        def clear
          Thread.current[THREAD_KEY] = nil
        end
      end
    end
  end
end
