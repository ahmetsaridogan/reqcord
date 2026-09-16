# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"

require "reqcord"

begin
  require "action_controller"
  require "action_dispatch"
  # `mount` asks whether the app is a Railtie; the constant has to exist even
  # though no application is booted here.
  require "rails/railtie"
  ACTIONPACK_AVAILABLE = true
rescue LoadError
  ACTIONPACK_AVAILABLE = false
end

module Reqcord
  module TestHelpers
    def configuration_for(root, yaml = nil)
      File.write(File.join(root, "reqcord.yml"), yaml) if yaml

      Configuration.load(root: root)
    end

    # Mirrors what the integration patch writes to the capture file: plain
    # JSON types with string keys.
    def exchange(**overrides)
      {
        "request" => {
          "method" => "POST",
          "path" => "/api/v2/customers",
          "path_params" => {},
          "query_params" => {},
          "headers" => {
            "Authorization" => "Bearer eyJhbGciOi",
            "X-Account-Id" => "42",
            "Content-Type" => "application/json"
          },
          "body" => { "customer" => { "name" => "John Doe", "email" => "john@example.com" } },
          "content_type" => "application/json"
        },
        "response" => {
          "status" => 201,
          "headers" => { "Content-Type" => "application/json", "X-Request-Id" => "abc" },
          "body" => { "id" => 42, "name" => "John Doe" },
          "content_type" => "application/json"
        },
        "source" => {
          "test" => "test_creates_customer",
          "suite" => "CustomersTest",
          "file" => "test/integration/customers_test.rb",
          "line" => 4
        }
      }.merge(overrides) { |_key, old, new| old.is_a?(Hash) && new.is_a?(Hash) ? old.merge(new) : new }
    end

    # The route block is instance_eval'd, but the parser still sees this
    # method's locals: a local named `resources` would shadow the DSL call.
    def customer_routes(only: [], version: nil, prefix: "/api")
      route_set = ActionDispatch::Routing::RouteSet.new

      route_set.draw do
        namespace :api do
          namespace :v2 do
            resources :customers, only: %i[index show create] do
              post :activate, on: :member
              resources :surveys, only: %i[index]
            end
          end
        end

        get "/health", to: "health#show"
      end

      Reqcord::RouteCollector.call(
        resources: only,
        version: version,
        prefix: prefix,
        route_set: route_set
      )
    end

    # Stands in for a mounted Rails::Engine: a Rack app with its own route
    # table, which is all the collector relies on.
    class BillingEngine
      def self.call(_env)
        [200, {}, ["ok"]]
      end

      def self.routes
        @routes ||= ActionDispatch::Routing::RouteSet.new.tap do |routes|
          routes.draw { resources :invoices, only: :index }
        end
      end
    end

    # Every route kind the collector must handle beyond `resources`.
    def mixed_route_set
      ActionDispatch::Routing::RouteSet.new.tap do |route_set|
        route_set.draw do
          match "/echo", to: "echo#any", via: %i[get post]
          match "/anything", to: "anything#any", via: :all
          mount Reqcord::TestHelpers::BillingEngine => "/billing", as: :billing
          mount ->(_env) { [200, {}, ["ok"]] } => "/rack", as: :rack
          get "/legacy", to: redirect("/customers")
          root to: "home#index"
          resource :cart, only: %i[show update]
          get "/items(/:id)", to: "items#show"
          get "/items-archive", to: "items#show", as: :items_archive
          get "/files/*path", to: "files#show", as: :file_download
          namespace :admin do
            resources :customers, only: :index
          end
          get "/rails/info", to: "rails/info#index", internal: true
        end
      end
    end

    def mixed_collector(only: [], version: nil, prefix: nil)
      Reqcord::RouteCollector.new(
        resources: only,
        version: version,
        prefix: prefix,
        route_set: mixed_route_set
      )
    end

    def mixed_routes(**options)
      mixed_collector(**options).call
    end
  end
end
