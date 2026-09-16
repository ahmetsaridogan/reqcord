# frozen_string_literal: true

# Entry point for the check test: the equivalent of `bin/rails reqcord:check`
# against the dummy application. Exits 1 with a file list when the committed
# documentation (REQCORD_OUTPUT) differs from what the code produces.
require_relative "app_boot"

result = Reqcord::Check.call

if result.clean?
  puts "up to date"
else
  puts "out of date"
  result.lines.each { |line| puts line }
  exit 1
end
