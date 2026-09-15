# frozen_string_literal: true

require "open3"
require "socket"

# The dummy application, documented once and served once over real HTTP, so
# the generated cURL commands and the Postman collection can be executed
# against it by every test that wants to.
module DummyServer
  DUMMY = File.expand_path("../dummy", __dir__)
  TOKEN = "integration-test-token"

  class << self
    def documentation
      @documentation ||= begin
        output = Dir.mktmpdir("reqcord-served")
        Minitest.after_run { FileUtils.rm_rf(output) }

        stdout, status = Open3.capture2e(
          { "REQCORD_OUTPUT" => output },
          RbConfig.ruby,
          File.join(DUMMY, "generate.rb"),
          chdir: DUMMY
        )

        raise "could not generate documentation:\n#{stdout}" unless status.success?

        output
      end
    end

    def port
      start_server unless @port

      @port
    end

    def base_url
      "http://127.0.0.1:#{port}"
    end

    private

    def start_server
      port = find_free_port

      @stdin, @output, @wait = Open3.popen2e(
        { "PORT" => port.to_s },
        RbConfig.ruby,
        File.join(DUMMY, "serve.rb"),
        chdir: DUMMY
      )

      Minitest.after_run { stop_server }

      wait_until_listening(port)

      @port = port
    end

    def stop_server
      Process.kill("TERM", @wait.pid) if @wait&.alive?
      @stdin&.close
      @output&.close
    rescue Errno::ESRCH, IOError
      nil
    end

    def find_free_port
      socket = TCPServer.new("127.0.0.1", 0)
      port = socket.addr[1]
      socket.close
      port
    end

    def wait_until_listening(port, timeout: 30)
      deadline = Time.now + timeout

      while Time.now < deadline
        begin
          TCPSocket.new("127.0.0.1", port).close
          return true
        rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL
          raise "server exited: #{@output.read}" unless @wait.alive?

          sleep 0.1
        end
      end

      raise "server did not start within #{timeout}s"
    end
  end
end
