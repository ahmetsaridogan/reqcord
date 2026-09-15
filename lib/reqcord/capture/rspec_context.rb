# frozen_string_literal: true

module Reqcord
  module Capture
    # The RSpec counterpart of MinitestContext: names captured examples after
    # the request spec that produced them.
    module RSpecContext
      class << self
        def install!(rspec = ::RSpec)
          return false if @installed

          rspec.configure do |config|
            config.before(:each) do |example|
              TestContext.current = RSpecContext.context_for(example)
            end

            config.after(:each) do
              TestContext.clear
            end
          end

          @installed = true
        end

        def installed?
          @installed == true
        end

        def context_for(example)
          metadata = example.metadata

          {
            test: metadata[:description],
            suite: metadata[:example_group][:description],
            file: metadata[:file_path],
            line: metadata[:line_number]
          }
        end
      end
    end
  end
end
