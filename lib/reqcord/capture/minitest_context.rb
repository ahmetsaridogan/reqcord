# frozen_string_literal: true

module Reqcord
  module Capture
    module MinitestContext
      def before_setup
        file, line = reqcord_source_location

        TestContext.current = {
          test: name,
          suite: self.class.name,
          file: file,
          line: line
        }

        super
      end

      def after_teardown
        super
      ensure
        TestContext.clear
      end

      private

      def reqcord_source_location
        method(name).source_location
      rescue NameError
        [nil, nil]
      end
    end
  end
end
