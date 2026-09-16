# frozen_string_literal: true

# A store API in one file: closer to a real application than test-app, so the
# generated documentation shows the harder cases.
#
#   GET  /api/v1                          root inside a namespace ("Home")
#   POST /api/v1/auth/login               form-encoded, token in the response body
#   GET|PATCH /api/v1/profile             singular resource, PATCH and PUT folded
#   GET  /api/v1/products                 filter[category], sort, page, per_page
#   GET  /api/v1/products/search          collection action, 400 without q
#   GET  /api/v1/orders/:id               403 for someone else's order
#   POST /api/v1/orders                   line_items[] and a nested address
#   POST /api/v1/orders/:id/cancel        409 once shipped
#   GET  /api/v1/orders/:order_id/notes   nested resource
#   GET  /api/v1/cart                     singular resource with nested items
#   POST /api/v1/cart/items               add by sku, DELETE /cart/items/:sku
#   POST /api/v1/cart/checkout            payment_method: "card" | "bank_transfer"
#   */api/v1/admin/products               X-Api-Key, 409 on a duplicate sku
#   POST /api/v1/admin/products/:id/image  multipart upload, documented by file name
#   GET  /api/v2/products                 a second API version, cursor paging
ENV["RAILS_ENV"] ||= "test"

# Only needed because this example lives inside the Reqcord repository.
# In your own application, `gem "reqcord"` in the Gemfile is enough.
$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)

require "rails"
require "action_controller/railtie"
require "reqcord"

class ComplexApp < Rails::Application
  config.root = __dir__
  config.eager_load = false
  config.logger = Logger.new(IO::NULL)
  config.secret_key_base = "a" * 64
  config.hosts.clear
end

Rails.application.initialize!

module Store
  PRODUCTS = [
    { id: 1, sku: "TEA-001", name: "Earl Grey", category: "tea", price_cents: 1200, cost_cents: 500, tags: %w[black bergamot] },
    { id: 2, sku: "TEA-002", name: "Sencha", category: "tea", price_cents: 1500, cost_cents: 700, tags: %w[green] },
    { id: 3, sku: "MUG-001", name: "Stoneware Mug", category: "mugs", price_cents: 2400, cost_cents: 900, tags: %w[ceramic] },
    { id: 4, sku: "MUG-002", name: "Travel Mug", category: "mugs", price_cents: 3200, cost_cents: 1400, tags: %w[steel insulated] }
  ].freeze

  PUBLIC_PRODUCT = %i[id sku name category price_cents tags].freeze

  ORDERS = [
    { id: 1, user_id: 1, status: "pending", currency: "USD", total_cents: 2700 },
    { id: 2, user_id: 1, status: "shipped", currency: "USD", total_cents: 3200 },
    { id: 3, user_id: 2, status: "pending", currency: "EUR", total_cents: 1500 }
  ].freeze

  NOTES = [
    { id: 1, order_id: 1, body: "Leave at the door", author: "ada" },
    { id: 2, order_id: 1, body: "Gift wrap please", author: "ada" }
  ].freeze

  PROFILE = { id: 1, name: "Ada Lovelace", email: "ada@example.com", locale: "en" }.freeze
  LOCALES = %w[en tr].freeze

  CART_ITEMS = [
    { sku: "TEA-001", name: "Earl Grey", quantity: 2, unit_price_cents: 1200 },
    { sku: "MUG-001", name: "Stoneware Mug", quantity: 1, unit_price_cents: 2400 }
  ].freeze
  PAYMENT_METHODS = %w[card bank_transfer].freeze
end

module Api
  module V1
    class BaseController < ActionController::API
      private

      def authenticate!
        return if request.headers["Authorization"].present?

        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def not_found
        render json: { error: "Not Found" }, status: :not_found
      end
    end

    class HomeController < BaseController
      def index
        render json: { name: "Store API", version: "v1", links: { products: "/api/v1/products", orders: "/api/v1/orders" } }
      end
    end

    class AuthController < BaseController
      # A classic form login: the test posts a form, not JSON.
      def login
        if params[:email] == "ada@example.com" && params[:password] == "correct-horse-battery"
          render json: { token: "tok_live_9f8e7d6c", token_type: "Bearer", expires_in: 3600 }
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end
    end

    class ProfilesController < BaseController
      before_action :authenticate!

      def show
        render json: Store::PROFILE
      end

      def update
        attributes = params.require(:profile).permit(:name, :locale).to_h.symbolize_keys

        if attributes.key?(:locale) && !Store::LOCALES.include?(attributes[:locale])
          return render(json: { errors: { locale: ["is not included in the list"] } }, status: :unprocessable_entity)
        end

        render json: Store::PROFILE.merge(attributes)
      end
    end

    class ProductsController < BaseController
      def index
        products = Store::PRODUCTS
        category = params.dig(:filter, :category)
        products = products.select { |product| product[:category] == category } if category.present?
        products = products.sort_by { |product| product[:price_cents] } if params[:sort] == "price_asc"
        products = products.sort_by { |product| -product[:price_cents] } if params[:sort] == "price_desc"

        page = params.fetch(:page, 1).to_i
        per_page = params.fetch(:per_page, 2).to_i
        slice = products.each_slice(per_page).to_a[page - 1] || []

        render json: {
          data: slice.map { |product| product.slice(*Store::PUBLIC_PRODUCT) },
          meta: { page: page, per_page: per_page, total: products.size }
        }
      end

      def show
        product = Store::PRODUCTS.find { |candidate| candidate[:id] == params[:id].to_i }

        return not_found unless product

        render json: product.slice(*Store::PUBLIC_PRODUCT)
      end

      def search
        query = params[:q].to_s.strip

        return render(json: { error: "q is required" }, status: :bad_request) if query.empty?

        matches = Store::PRODUCTS.select { |product| product[:name].downcase.include?(query.downcase) }

        render json: { query: query, results: matches.map { |product| product.slice(*Store::PUBLIC_PRODUCT) } }
      end
    end

    class OrdersController < BaseController
      before_action :authenticate!
      before_action :find_order, only: %i[show cancel destroy]

      def index
        orders = Store::ORDERS.select { |order| order[:user_id] == 1 }
        orders = orders.select { |order| order[:status] == params[:status] } if params[:status].present?

        render json: orders
      end

      def show
        return render(json: { error: "Forbidden" }, status: :forbidden) unless @order[:user_id] == 1

        render json: @order
      end

      def create
        attributes = params.require(:order)
                           .permit(line_items: %i[sku quantity], shipping_address: %i[line1 city country])
                           .to_h.deep_symbolize_keys
        items = Array(attributes[:line_items])

        return render(json: { errors: { line_items: ["can't be blank"] } }, status: :unprocessable_entity) if items.empty?

        lines = items.map do |item|
          product = Store::PRODUCTS.find { |candidate| candidate[:sku] == item[:sku] }

          return render(json: { errors: { sku: ["#{item[:sku]} is not a known product"] } }, status: :unprocessable_entity) unless product

          quantity = item[:quantity].to_i
          {
            sku: product[:sku], name: product[:name], quantity: quantity,
            unit_price_cents: product[:price_cents], subtotal_cents: product[:price_cents] * quantity
          }
        end

        render json: {
          id: 4, status: "pending", currency: "USD",
          total_cents: lines.sum { |line| line[:subtotal_cents] },
          line_items: lines,
          shipping_address: attributes[:shipping_address]
        }, status: :created
      end

      def cancel
        if @order[:status] == "shipped"
          return render(json: { error: "Shipped orders cannot be cancelled" }, status: :conflict)
        end

        render json: @order.merge(status: "cancelled")
      end

      def destroy
        head :no_content
      end

      private

      def find_order
        @order = Store::ORDERS.find { |order| order[:id] == params[:id].to_i }

        not_found unless @order
      end
    end

    # Nested under an order: /api/v1/orders/:order_id/notes
    class NotesController < BaseController
      before_action :authenticate!
      before_action :find_order

      def index
        render json: Store::NOTES.select { |note| note[:order_id] == @order[:id] }
      end

      def create
        body = params.dig(:note, :body).to_s

        return render(json: { errors: { body: ["can't be blank"] } }, status: :unprocessable_entity) if body.empty?

        render json: { id: 3, order_id: @order[:id], body: body, author: "ada" }, status: :created
      end

      private

      def find_order
        @order = Store::ORDERS.find { |order| order[:id] == params[:order_id].to_i }

        not_found unless @order
      end
    end

    # `resource :cart`: one cart per customer, no id in the path.
    class CartsController < BaseController
      before_action :authenticate!

      def show
        render json: cart
      end

      # Turns the cart into an order.
      def checkout
        method = params[:payment_method].to_s

        unless Store::PAYMENT_METHODS.include?(method)
          return render(json: { errors: { payment_method: ["is not included in the list"] } }, status: :unprocessable_entity)
        end

        render json: { id: 5, status: "pending", payment_method: method, total_cents: cart[:total_cents], line_items: cart[:items] },
               status: :created
      end

      private

      def cart
        { items: Store::CART_ITEMS, total_cents: Store::CART_ITEMS.sum { |item| item[:quantity] * item[:unit_price_cents] } }
      end
    end

    # Nested under the cart and addressed by sku: /api/v1/cart/items/:sku
    class CartItemsController < BaseController
      before_action :authenticate!

      def create
        attributes = params.require(:item).permit(:sku, :quantity).to_h.symbolize_keys
        product = Store::PRODUCTS.find { |candidate| candidate[:sku] == attributes[:sku] }

        return render(json: { errors: { sku: ["#{attributes[:sku]} is not a known product"] } }, status: :unprocessable_entity) unless product

        render json: { sku: product[:sku], name: product[:name], quantity: attributes[:quantity].to_i, unit_price_cents: product[:price_cents] },
               status: :created
      end

      def destroy
        return not_found unless Store::CART_ITEMS.any? { |item| item[:sku] == params[:sku] }

        head :no_content
      end
    end

    module Admin
      # A different credential (X-Api-Key) and a fuller view of the same data.
      class ProductsController < BaseController
        before_action :require_api_key

        def index
          render json: Store::PRODUCTS
        end

        def create
          attributes = params.require(:product).permit(:sku, :name, :category, :price_cents).to_h.symbolize_keys

          if attributes[:sku].to_s.empty? || attributes[:name].to_s.empty?
            return render(json: { errors: { sku: ["can't be blank"] } }, status: :unprocessable_entity)
          end

          if Store::PRODUCTS.any? { |product| product[:sku] == attributes[:sku] }
            return render(json: { error: "sku #{attributes[:sku]} already exists" }, status: :conflict)
          end

          render json: { id: 5, cost_cents: 0, tags: [], **attributes }, status: :created
        end

        def destroy
          return not_found unless Store::PRODUCTS.any? { |product| product[:id] == params[:id].to_i }

          head :no_content
        end

        private

        def require_api_key
          return if request.headers["X-Api-Key"].present?

          render json: { error: "API key required" }, status: :unauthorized
        end
      end

      # A multipart upload: the image's name and type are documented, its
      # bytes are not.
      class ProductImagesController < BaseController
        before_action :require_api_key

        def create
          return not_found unless Store::PRODUCTS.any? { |product| product[:id] == params[:product_id].to_i }

          image = params[:image]

          unless image.respond_to?(:original_filename)
            return render(json: { errors: { image: ["must be a file"] } }, status: :unprocessable_entity)
          end

          render json: {
            product_id: params[:product_id].to_i,
            filename: image.original_filename,
            content_type: image.content_type,
            alt: params[:alt]
          }, status: :created
        end

        private

        def require_api_key
          return if request.headers["X-Api-Key"].present?

          render json: { error: "API key required" }, status: :unauthorized
        end
      end
    end
  end

  module V2
    class ProductsController < ActionController::API
      # v2 pages by cursor instead of page numbers.
      def index
        start = params[:cursor].present? ? 2 : 0
        items = Store::PRODUCTS[start, 2].map { |product| product.slice(*Store::PUBLIC_PRODUCT).merge(price: format("%.2f", product[:price_cents] / 100.0)) }

        render json: { items: items, next_cursor: start.zero? ? "eyJpZCI6Mn0" : nil }
      end
    end
  end
end

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      root to: "home#index"

      post "auth/login", to: "auth#login"

      resource :profile, only: %i[show update]

      resources :products, only: %i[index show] do
        get :search, on: :collection
      end

      resources :orders, only: %i[index show create destroy] do
        post :cancel, on: :member
        resources :notes, only: %i[index create]
      end

      resource :cart, only: :show do
        post :checkout
        resources :items, only: %i[create destroy], controller: "cart_items", param: :sku
      end

      namespace :admin do
        resources :products, only: %i[index create destroy] do
          resource :image, only: :create, controller: "product_images"
        end
      end
    end

    namespace :v2 do
      resources :products, only: :index
    end
  end
end
