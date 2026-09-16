# frozen_string_literal: true

require "json"
require "yaml"
require "time"
require "uri"
require "rack/utils"
require "fileutils"
require "pathname"

require_relative "reqcord/version"
require_relative "reqcord/errors"
require_relative "reqcord/support"
require_relative "reqcord/configuration"

require_relative "reqcord/request_example"
require_relative "reqcord/response_example"
require_relative "reqcord/schema"
require_relative "reqcord/endpoint"
require_relative "reqcord/dataset"

require_relative "reqcord/route_collector"

require_relative "reqcord/capture"
require_relative "reqcord/capture/test_context"
require_relative "reqcord/capture/collector"

require_relative "reqcord/sanitizers/sanitizer"
require_relative "reqcord/renderers/payload"
require_relative "reqcord/renderers/curl"
require_relative "reqcord/exporters"
require_relative "reqcord/exporters/curl"
require_relative "reqcord/exporters/markdown"
require_relative "reqcord/exporters/postman"
require_relative "reqcord/exporters/openapi"
require_relative "reqcord/generator"

require_relative "reqcord/railtie" if defined?(Rails::Railtie)

module Reqcord
  class << self
    attr_writer :root

    def root
      return @root if @root

      if defined?(Rails) &&
         Rails.respond_to?(:root) &&
         Rails.root

        Rails.root
      else
        Pathname(Dir.pwd)
      end
    end

    def configuration
      @configuration ||=
        Configuration.load(
          root: root
        )
    end

    def reload_configuration!
      @configuration =
        Configuration.load(
          root: root
        )
    end

    def log(message)
      $stdout.puts("[reqcord] #{message}")
    end

    def warn(message)
      $stderr.puts("[reqcord] #{message}")
    end
  end
end
