# frozen_string_literal: true

# Serves the dummy application over real HTTP, so the generated cURL commands
# can be executed against it.
require_relative "app_boot"
require "puma"

port = Integer(ENV.fetch("PORT", "9876"))

server = Puma::Server.new(Rails.application)
server.add_tcp_listener("127.0.0.1", port)
server.run

$stdout.puts("listening on #{port}")
$stdout.flush

sleep
