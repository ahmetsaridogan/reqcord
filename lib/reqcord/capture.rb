# frozen_string_literal: true

module Reqcord
  # Capture runs inside the test process and writes to a file the generator
  # reads afterwards. Both variables are set by `reqcord:generate`, so an
  # ordinary test run patches nothing and writes nothing.
  module Capture
    class << self
      def enabled?
        ENV["REQCORD_CAPTURE"] == "1" &&
          capture_file
      end

      def capture_file
        ENV["REQCORD_CAPTURE_FILE"]
      end
    end
  end
end
