# frozen_string_literal: true

module Reqcord
  class Dataset
    # 2: endpoints carry `parameters` (path/query/body schemas), `responses`
    # (one schema + example per status), `route_name` and `also_methods`.
    SCHEMA_VERSION = 2

    # An endpoint page must not overwrite the resource or dataset pages.
    RESERVED_BASENAMES = {
      "index" => "list",
      "readme" => "readme-endpoint",
      "dataset" => "dataset-endpoint"
    }.freeze

    # Endpoints served by one controller, as the exporters walk them. Keyed by
    # the full controller path so `admin/users` and `api/v1/users` stay apart.
    class Resource
      attr_reader :name, :endpoints

      def initialize(name)
        @name = name.to_s
        @endpoints = []
      end

      def segments
        name.split("/")
      end

      def short_name
        segments.last.to_s
      end

      def namespace
        segments[0...-1].join("/")
      end

      # Nested directories / folders: api/v2/customers.
      def slug
        segments.map { |segment| Support.parameterize(segment) }.join("/")
      end

      def title
        Support.titleize(short_name)
      end

      def api_versions
        endpoints.map(&:api_version).compact.uniq.sort
      end

      # One stable file name per endpoint. Two routes sharing an action
      # (`match … via: [:get, :post]`) are told apart by verb, never by a
      # bare counter.
      def file_basenames
        bases = endpoints.to_h { |endpoint| [endpoint, RESERVED_BASENAMES.fetch(endpoint.slug, endpoint.slug)] }
        shared = bases.values.tally
        seen = Hash.new(0)

        bases.to_h do |endpoint, base|
          basename = shared[base] > 1 ? "#{base}-#{endpoint.method.downcase}" : base
          seen[basename] += 1
          basename = "#{basename}-#{seen[basename]}" if seen[basename] > 1

          [endpoint, basename]
        end
      end
    end

    # Rails emits both PATCH and PUT for `update`; one page serves both. The
    # verb a test used wins, PATCH when neither or both did.
    def self.fold_method_twins(endpoints)
      groups = endpoints.group_by { |endpoint| [endpoint.path, endpoint.controller, endpoint.action] }

      endpoints.filter_map do |endpoint|
        next endpoint unless %w[PATCH PUT].include?(endpoint.method)

        twins = groups.fetch([endpoint.path, endpoint.controller, endpoint.action])
                      .select { |candidate| %w[PATCH PUT].include?(candidate.method) }

        next endpoint unless twins.size == 2

        primary = twins.find(&:curl_ready?) || twins.find { |candidate| candidate.method == "PATCH" }

        next nil unless endpoint.equal?(primary)

        twin = twins.find { |candidate| !candidate.equal?(primary) }
        twin.request_examples.each { |example| primary.add_request_example(example) }
        twin.response_examples.each { |example| primary.add_response_example(example) }
        primary.also_methods = [twin.method]

        primary
      end
    end

    attr_reader :schema_version, :endpoints

    def initialize(
      schema_version: SCHEMA_VERSION,
      endpoints: []
    )
      @schema_version = schema_version
      @endpoints = endpoints
    end

    def add(endpoint)
      endpoints << endpoint
    end

    def empty?
      endpoints.empty?
    end

    # Endpoints for which Reqcord captured at least one successful 2xx
    # request. These are safe to use as canonical cURL/documentation examples.
    def curl_ready_endpoints
      endpoints.select(&:curl_ready?)
    end

    # Backwards-compatible alias for callers that previously asked for
    # documented endpoints. In the cURL-first MVP, documented means a
    # successful request was actually captured.
    def documented_endpoints
      curl_ready_endpoints
    end

    def uncovered_endpoints
      endpoints.reject(&:curl_ready?)
    end

    def resources
      grouped = endpoints.each_with_object({}) do |endpoint, memo|
        key = endpoint.controller.to_s.empty? ? endpoint.resource : endpoint.controller
        resource = memo[key] ||= Resource.new(key)
        resource.endpoints << endpoint
      end

      grouped.values.sort_by(&:name).each do |resource|
        resource.endpoints.sort_by! { |endpoint| [endpoint.path, endpoint.method] }
      end
    end

    def to_h
      {
        schema_version: schema_version,
        generated_at: Time.now.utc.iso8601,
        endpoints: curl_ready_endpoints.map(&:to_h),
        uncovered_routes: uncovered_endpoints.map do |endpoint|
          {
            name: endpoint.name,
            method: endpoint.method,
            path: endpoint.path,
            controller: endpoint.controller,
            action: endpoint.action,
            resource: endpoint.resource,
            api_version: endpoint.api_version,
            route_name: endpoint.route_name,
            also_methods: endpoint.also_methods
          }
        end
      }
    end

    def write(path)
      path = Pathname(path)

      FileUtils.mkdir_p(path.dirname)

      File.write(
        path,
        JSON.pretty_generate(to_h)
      )

      path.to_s
    end
  end
end
