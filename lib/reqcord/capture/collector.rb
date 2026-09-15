# frozen_string_literal: true

module Reqcord
  module Capture
    # Appends one JSON line per exchange. The lock keeps parallel test workers
    # from interleaving partial lines in the same file.
    class Collector
      class << self
        def write(exchange)
          return unless Capture.enabled?

          path = Capture.capture_file

          FileUtils.mkdir_p(File.dirname(path))

          File.open(path, "a") do |file|
            file.flock(File::LOCK_EX)

            file.puts(
              JSON.generate(exchange)
            )

            file.flush
          ensure
            file.flock(File::LOCK_UN)
          end
        end
      end
    end
  end
end
