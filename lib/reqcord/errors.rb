# frozen_string_literal: true

module Reqcord
  class Error < StandardError; end

  class ConfigurationError < Error; end

  class GenerationError < Error; end
end
