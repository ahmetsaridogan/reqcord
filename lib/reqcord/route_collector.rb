# frozen_string_literal: true

module Reqcord
  # The documented surface is the route table, not the captured traffic: every
  # matching route becomes an endpoint, and captures are attached to it. Routes
  # no test exercised stay in the dataset as documentation gaps.
  #
  # Nothing is dropped silently: a route either becomes a Route, or is counted
  # in `skipped` with the reason (redirect, Rack mount, Rails internal).
  class RouteCollector
    # A route that answers any verb (`via: :all`); the captured verb decides
    # what gets documented.
    ANY = "ANY"

    Route = Struct.new(
      :name,
      :method,
      :path,
      :controller,
      :action,
      :resource,
      :api_version,
      :rails_route,
      :mount_prefix,
      keyword_init: true
    ) do
      def endpoint(method: self.method)
        Endpoint.new(
          method: method,
          path: path,
          controller: controller,
          action: action,
          resource: resource,
          api_version: api_version,
          route_name: name
        )
      end

      def any_verb?
        method == ANY
      end

      def matches?(request_method, request_path)
        return false unless any_verb? || method == request_method.to_s.upcase

        relative = relative_path(request_path)
        return false if relative.nil?

        !!rails_route.path.match(relative)
      end

      private

      # An engine's pattern knows nothing about where it was mounted.
      def relative_path(request_path)
        return request_path if mount_prefix.nil? || mount_prefix.empty?
        return nil unless request_path.start_with?(mount_prefix)

        rest = request_path.delete_prefix(mount_prefix)
        return nil unless rest.empty? || rest.start_with?("/")

        rest.empty? ? "/" : rest
      end
    end

    def self.call(
      resources: [],
      version: nil,
      prefix: nil,
      route_set: nil
    )
      new(
        resources: resources,
        version: version,
        prefix: prefix,
        route_set: route_set
      ).call
    end

    # Routes that were seen but cannot be documented, by reason.
    attr_reader :skipped

    def initialize(resources:, version:, prefix:, route_set: nil)
      @resources = Array(resources).map(&:to_s)
      @version = version&.to_s
      @prefix = prefix
      @route_set = route_set
      @skipped = Hash.new(0)
    end

    def call
      @skipped = Hash.new(0)

      collect(route_set.routes, mount_prefix: nil)
    end

    def skipped_count
      skipped.values.sum
    end

    private

    attr_reader :resources, :version, :prefix

    def route_set
      @route_set ||= Rails.application.routes
    end

    def collect(rails_routes, mount_prefix:)
      rails_routes.flat_map { |rails_route| build_routes(rails_route, mount_prefix) }
    end

    def build_routes(rails_route, mount_prefix)
      return [] if rails_route.internal

      app = rails_route.app
      spec = normalize_path(rails_route.path.spec.to_s)

      # A mounted engine's routes live in its own table, relative to the mount.
      if engine?(app)
        return collect(app.rack_app.routes.routes, mount_prefix: join(mount_prefix, spec))
      end

      controller = rails_route.defaults[:controller]&.to_s
      action = rails_route.defaults[:action]&.to_s

      if controller.nil? || action.nil?
        @skipped[skip_reason(app)] += 1
        return []
      end

      return [] if internal?(controller)

      path = join(mount_prefix, spec)

      return [] unless matches_prefix?(path)
      return [] unless matches_version?(controller, path)

      resource = controller.split("/").last

      return [] unless matches_resource?(resource, controller)

      normalize_methods(rails_route.verb).map do |method|
        Route.new(
          name: rails_route.name,
          method: method,
          path: path,
          controller: controller,
          action: action,
          resource: resource,
          api_version: detect_version(controller, path),
          rails_route: rails_route,
          mount_prefix: mount_prefix
        )
      end
    end

    # A mounted app that carries its own route table (a Rails::Engine, or
    # anything shaped like one). Checked by shape rather than by class: the
    # `Rails::Engine` constant need not be loaded, and a Sinatra app — whose
    # `routes` is a plain Hash — is a Rack mount, not an engine.
    def engine?(app)
      return false unless app.respond_to?(:rack_app)

      rack_app = app.rack_app

      rack_app.respond_to?(:routes) && rack_app.routes.respond_to?(:routes)
    end

    def skip_reason(app)
      rack_app = app.respond_to?(:rack_app) ? app.rack_app : app

      if defined?(ActionDispatch::Routing::Redirect) && rack_app.is_a?(ActionDispatch::Routing::Redirect)
        "redirect"
      else
        "mount"
      end
    end

    # Rails 8 exposes the verb as a plain string: "GET", "GET|POST" for
    # `via: [:get, :post]`, "" for `via: :all`. Older versions used a regexp
    # whose source carried anchors.
    def normalize_methods(verb)
      values = verb.to_s
                   .gsub(/[$^]/, "")
                   .split("|")
                   .map(&:strip)
                   .reject(&:empty?)
                   .map(&:upcase)

      values.empty? ? [ANY] : values
    end

    def normalize_path(path)
      path.sub(/\(\.:format\)\z/, "")
    end

    def join(mount_prefix, path)
      return path if mount_prefix.nil? || mount_prefix.empty?
      return mount_prefix if path == "/"

      "#{mount_prefix}#{path}"
    end

    def internal?(controller)
      controller.start_with?(
        "rails/",
        "active_storage/",
        "action_mailbox/",
        "turbo/"
      )
    end

    # `prefix` is one string or a list; nothing configured means every route.
    def matches_prefix?(path)
      prefixes = Array(prefix).map(&:to_s).reject(&:empty?)
      return true if prefixes.empty?

      # Segment-wise: `/api` covers `/api`, `/api/v1/…` and `/api(/:id)`, not
      # `/api-docs`.
      prefixes.any? do |candidate|
        candidate = candidate.chomp("/")
        next true if candidate.empty?
        next false unless path.start_with?(candidate)

        rest = path.delete_prefix(candidate)
        rest.empty? || rest.start_with?("/", "(")
      end
    end

    # `RESOURCE=customers`, `RESOURCE=cart` (a singular resource is served by
    # `carts`) and `RESOURCE=api/v2/customers` all name the same thing.
    def matches_resource?(resource, controller)
      return true if resources.empty?

      candidates = [resource, controller, Support.singularize(resource)]

      resources.any? { |wanted| candidates.include?(wanted) }
    end

    def matches_version?(controller, path)
      return true if version.nil? || version.empty?

      controller.split("/").include?(version) ||
        path.split("/").include?(version)
    end

    def detect_version(controller, path)
      controller.split("/").find { |segment| segment.match?(/\Av\d+\z/) } ||
        path.split("/").find { |segment| segment.match?(/\Av\d+\z/) }
    end
  end
end
