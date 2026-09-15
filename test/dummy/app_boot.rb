# frozen_string_literal: true

# A single file Rails application, used to exercise the whole pipeline the way
# a host application would: boot, routes, controllers, integration tests. Its
# route table deliberately holds every route kind Reqcord has to handle, not
# only `resources`.
ENV["RAILS_ENV"] ||= "test"

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)

require "rails"
require "action_controller/railtie"
require "reqcord"

class DummyApp < Rails::Application
  config.root = __dir__
  config.eager_load = false
  config.logger = Logger.new(IO::NULL)
  config.secret_key_base = "a" * 64
  config.hosts.clear
end

# A mounted engine with its own route table.
class Billing < Rails::Engine
  isolate_namespace Billing
end

Rails.application.initialize!

module Api
  module V2
    class CustomersController < ActionController::API
      def index
        render json: [{ id: 42, name: "John Doe" }]
      end

      def show
        render json: { id: params[:id].to_i, name: "John Doe" }
      end

      def create
        return render(json: { error: "Unauthorized" }, status: :unauthorized) if request.headers["Authorization"].blank?

        if params.dig(:customer, :email) == "taken@example.com"
          render json: { errors: { email: ["has already been taken"] } }, status: :unprocessable_entity
        else
          render json: { id: 42, name: params.dig(:customer, :name), password: "hunter2" }, status: :created
        end
      end

      # Deliberately left untested, to prove uncovered routes are reported.
      def activate
        render json: { id: params[:id].to_i, active: true }
      end
    end
  end

  module Admin
    class CustomersController < ActionController::API
      def index
        render json: [{ id: 42, name: "John Doe", internal_note: "vip" }]
      end
    end
  end

  class HomeController < ActionController::API
    def index
      render json: { name: "Dummy API", version: "v2" }
    end
  end

  class EchoController < ActionController::API
    def any
      render json: { method: request.method, echoed: params.except(:controller, :action, :format).to_unsafe_h }
    end
  end

  class AnythingController < ActionController::API
    def any
      render json: { method: request.method }
    end
  end

  class CartsController < ActionController::API
    def show
      render json: { items: [], coupon: nil }
    end

    def update
      render json: { items: [], coupon: params.dig(:cart, :coupon) }
    end
  end

  class ItemsController < ActionController::API
    def show
      render json: params[:id] ? { id: params[:id].to_i } : [{ id: 1 }, { id: 2 }]
    end
  end

  class FilesController < ActionController::API
    def show
      render json: { path: params[:path] }
    end
  end
end

# Reopened as the class it is (a Rails::Engine), not as a module.
class Billing
  class InvoicesController < ActionController::API
    def index
      render json: [{ number: "INV-1", total_cents: 1200 }]
    end
  end
end

Billing.routes.draw do
  resources :invoices, only: :index
end

Rails.application.routes.draw do
  namespace :api do
    root to: "home#index"

    namespace :v2 do
      resources :customers, only: %i[index show create] do
        post :activate, on: :member
      end
    end

    namespace :admin do
      resources :customers, only: :index
    end

    match "echo", to: "echo#any", via: %i[get post]
    match "anything", to: "anything#any", via: :all

    resource :cart, only: %i[show update]

    get "items(/:id)", to: "items#show"
    get "files/*path", to: "files#show", as: :file_download

    get "legacy", to: redirect("/api/v2/customers")
  end

  mount Billing => "/api/billing"
  mount ->(_env) { [200, { "content-type" => "text/plain" }, ["ok"]] } => "/api/rack", as: :rack

  get "/health", to: "health#show"
end
