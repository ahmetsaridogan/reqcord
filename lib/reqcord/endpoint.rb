# frozen_string_literal: true

module Reqcord
  class Endpoint
    ACTION_TITLES = {
      "index" => "List %<plural>s",
      "show" => "Get %<singular>s",
      "create" => "Create %<singular>s",
      "update" => "Update %<singular>s",
      "destroy" => "Delete %<singular>s",
      "new" => "New %<singular>s",
      "edit" => "Edit %<singular>s"
    }.freeze

    # One status the endpoint was seen to return, described by every body
    # captured with that status; the first capture stands as the example.
    Response = Struct.new(:status, :schema, :examples, keyword_init: true) do
      def example
        examples.first
      end

      def to_h
        {
          status: status,
          schema: schema.to_a,
          example: example.body,
          headers: example.headers,
          content_type: example.content_type
        }
      end
    end

    attr_accessor :name,
                  :method,
                  :path,
                  :controller,
                  :action,
                  :resource,
                  :api_version,
                  :route_name,
                  :also_methods,
                  :request_examples,
                  :response_examples

    def initialize(
      method:,
      path:,
      controller:,
      action:,
      name: nil,
      resource: nil,
      api_version: nil,
      route_name: nil,
      also_methods: [],
      request_examples: [],
      response_examples: []
    )
      @method = method.to_s.upcase
      @path = path
      @controller = controller
      @action = action
      @resource = resource || infer_resource(controller)
      @api_version = api_version
      @route_name = route_name
      @also_methods = also_methods
      @request_examples = request_examples
      @response_examples = response_examples
      @name = name || default_name
    end

    def http_method
      method
    end

    def key
      "#{method} #{path}"
    end

    # A request only counts as successful through the status it received, so
    # the pair is what tells us; callers should not have to set it by hand.
    def add_exchange(request:, response:)
      request.response_status ||= response.status if request && response

      add_request_example(request)
      add_response_example(response)
    end

    def add_request_example(example)
      return if example.nil?
      return if request_examples.any? { |candidate| candidate.signature == example.signature }

      reset_schemas!
      request_examples << example
    end

    def add_response_example(example)
      return if example.nil?
      return if response_examples.any? { |candidate| candidate.signature == example.signature }

      response_examples << example
    end

    def documented?
      !request_examples.empty? || !response_examples.empty?
    end

    # cURL examples must come from a request that the application actually
    # accepted. Error-case payloads are valuable response examples, but they
    # must never become the endpoint's canonical request example.
    def primary_request_example
      successful_request_examples.first
    end

    def curl_ready?
      !primary_request_example.nil?
    end

    def successful_request_examples
      request_examples.select(&:successful?)
    end

    def documented_request_examples
      successful = successful_request_examples
      successful.empty? ? request_examples : successful
    end

    def responses_by_status
      response_examples.group_by(&:status).sort_by { |status, _| status }.to_h
    end

    # Every status seen, each with a schema inferred from all of its bodies.
    # Non-JSON bodies (plain text, HTML) carry no fields to describe.
    def responses
      responses_by_status.map do |status, examples|
        bodies = examples.map(&:body).select { |body| body.is_a?(Hash) || body.is_a?(Array) }

        Response.new(status: status, schema: Schema.infer(bodies, repetition: false), examples: examples)
      end
    end

    # What the endpoint accepts, described only by requests the application
    # accepted: a rejected payload says what the API refuses, not what it takes.
    def body_schema
      @body_schema ||= Schema.infer(successful_request_examples.map(&:body))
    end

    def query_schema
      @query_schema ||= Schema.infer(successful_request_examples.map(&:query_params))
    end

    def path_param_schema
      @path_param_schema ||= Schema.infer(successful_request_examples.map(&:path_params))
    end

    # A member route addresses one record: a required `:param` follows the
    # resource segment. Optional groups (`/items(/:id)`) and globs
    # (`/files/*path`) do not make a route a member route.
    def member?
      segments = required_path.split("/").reject(&:empty?)
      singular = Support.singularize(resource.to_s)
      index = segments.rindex { |segment| segment == resource.to_s || segment == singular }

      # `resource :cart` is served by CartsController at /cart: one record,
      # so its custom actions (/cart/checkout) address that one record.
      return true if index && segments[index] == singular && singular != resource.to_s

      candidates = index ? segments[(index + 1)..] : segments

      candidates.any? { |segment| segment.start_with?(":") }
    end

    # Every dynamic segment, including globs and those inside optional groups.
    def path_params
      path.scan(/[:*]([a-zA-Z_][a-zA-Z0-9_]*)/).flatten
    end

    # The path with its optional groups removed: what a request must carry.
    def required_path
      stripped = path.to_s

      stripped = stripped.gsub(/\([^()]*\)/, "") while stripped.match?(/\([^()]*\)/)

      stripped
    end

    def slug
      Support.parameterize(action.to_s.empty? ? key : action)
    end

    def to_h
      {
        name: name,
        method: method,
        path: path,
        controller: controller,
        action: action,
        resource: resource,
        api_version: api_version,
        route_name: route_name,
        also_methods: also_methods,
        path_params: path_params,
        parameters: {
          path: path_param_schema.to_a,
          query: query_schema.to_a,
          body: body_schema.to_a
        },
        responses: responses.map(&:to_h),
        request_examples: request_examples.map(&:to_h),
        response_examples: response_examples.map(&:to_h)
      }
    end

    private

    def reset_schemas!
      @body_schema = nil
      @query_schema = nil
      @path_param_schema = nil
    end

    def infer_resource(controller)
      controller.to_s.split("/").last
    end

    def default_name
      label = resource.to_s.empty? ? "resource" : resource.to_s.tr("/", " ")
      plural = Support.titleize(Support.pluralize(label))
      singular = Support.titleize(Support.singularize(label))

      # `root to: "home#index"` is a page, not a list of homes.
      return singular if action.to_s == "index" && !resource_in_path?

      template = ACTION_TITLES[action.to_s]
      return format(template, plural: plural, singular: singular) if template
      return plural if action.to_s.empty?

      # `post "auth/login", to: "auth#login"`: the action is the page, the
      # controller is only where it lives — "Login", not "Login Auths".
      return Support.titleize(action) if singular_resource? && action_in_path?

      "#{Support.titleize(action)} #{member? || singular_resource? ? singular : plural}".strip
    end

    # A controller named for one thing (auth, home, health) rather than a
    # collection (customers).
    def singular_resource?
      Support.pluralize(resource.to_s) != resource.to_s
    end

    def action_in_path?
      required_path.split("/").last.to_s == action.to_s
    end

    # Whether the path itself names the resource (/customers, /cart), as
    # opposed to a route like `/` or `/dashboard` served by some controller.
    def resource_in_path?
      static = required_path.split("/").reject { |segment| segment.empty? || segment.start_with?(":", "*") }
      names = [resource.to_s, Support.singularize(resource.to_s)]

      static.any? { |segment| names.include?(segment) }
    end
  end
end
