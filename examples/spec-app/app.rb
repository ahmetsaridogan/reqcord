# frozen_string_literal: true

# A tiny Rails API, in one file, so the example stays readable. In a real
# application this is just your app; Reqcord does not care how it is built.
#
# The same three resources as test-app — customers, users, tasks — so the two
# examples can be compared endpoint for endpoint.
ENV["RAILS_ENV"] ||= "test"

# Only needed because this example lives inside the Reqcord repository.
# In your own application, `gem "reqcord"` in the Gemfile is enough.
$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)

require "rails"
require "action_controller/railtie"
require "reqcord"

class ExampleApp < Rails::Application
  config.root = __dir__
  config.eager_load = false
  config.logger = Logger.new(IO::NULL)
  config.secret_key_base = "a" * 64
  config.hosts.clear
end

Rails.application.initialize!

module Api
  module V1
    class CustomersController < ActionController::API
      CUSTOMERS = [
        { id: 1, name: "John Doe", email: "john@example.com" },
        { id: 2, name: "Jane Roe", email: "jane@example.com" }
      ].freeze

      before_action :authenticate!

      def index
        render json: CUSTOMERS.first(params.fetch(:per_page, 25).to_i)
      end

      def show
        customer = CUSTOMERS.find { |record| record[:id] == params[:id].to_i }

        return render(json: { error: "Not Found" }, status: :not_found) unless customer

        render json: customer
      end

      STATUSES = %w[active passive].freeze

      def create
        if params.dig(:customer, :email).to_s.empty?
          return render(
            json: { errors: { email: ["can't be blank"] } },
            status: :unprocessable_entity
          )
        end

        unless STATUSES.include?(params.dig(:customer, :status).to_s)
          return render(
            json: { errors: { status: ["is not included in the list"] } },
            status: :unprocessable_entity
          )
        end

        render json: { id: 3, **customer_params }, status: :created
      end

      private

      def authenticate!
        return if request.headers["Authorization"].present?

        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def customer_params
        params.require(:customer).permit(:name, :email, :status).to_h.symbolize_keys
      end
    end

    class UsersController < ActionController::API
      USERS = [
        { id: 1, name: "John Doe", email: "john@example.com" },
        { id: 2, name: "Jane Roe", email: "jane@example.com" }
      ].freeze

      before_action :authenticate!

      def index
        render json: USERS.first(params.fetch(:per_page, 25).to_i)
      end

      def show
        user = USERS.find { |record| record[:id] == params[:id].to_i }

        return render(json: { error: "Not Found" }, status: :not_found) unless user

        render json: user
      end

      STATUSES = %w[active inactive].freeze

      def create
        if params.dig(:user, :email).to_s.empty?
          return render(
            json: { errors: { email: ["can't be blank"] } },
            status: :unprocessable_entity
          )
        end

        unless STATUSES.include?(params.dig(:user, :status).to_s)
          return render(
            json: { errors: { status: ["is not included in the list"] } },
            status: :unprocessable_entity
          )
        end

        render json: { id: 3, **user_params }, status: :created
      end

      private

      def authenticate!
        return if request.headers["Authorization"].present?

        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def user_params
        params.require(:user).permit(:name, :email, :status).to_h.symbolize_keys
      end
    end

    class TasksController < ActionController::API
      TASKS = [
        { id: 1, title: "Write the docs", status: "open", priority: "high" },
        { id: 2, title: "Ship 0.1.1", status: "done", priority: "high" },
        { id: 3, title: "Tidy the backlog", status: "open", priority: "low" }
      ].freeze

      STATUSES = %w[open done].freeze
      PRIORITIES = %w[low high].freeze

      def index
        tasks = TASKS
        tasks = tasks.select { |task| task[:status] == params[:status] } if params[:status].present?

        render json: tasks
      end

      before_action :find_task, only: %i[show update complete destroy]

      def show
        render json: @task
      end

      def create
        if params.dig(:task, :title).to_s.empty?
          return render(json: { errors: { title: ["can't be blank"] } }, status: :unprocessable_entity)
        end

        unless PRIORITIES.include?(params.dig(:task, :priority).to_s)
          return render(json: { errors: { priority: ["is not included in the list"] } }, status: :unprocessable_entity)
        end

        render json: { id: 4, status: "open", **task_params }, status: :created
      end

      def update
        render json: @task.merge(task_params)
      end

      def complete
        render json: @task.merge(status: "done")
      end

      def destroy
        head :no_content
      end

      private

      # Rendering in a before_action halts the chain, so the action never runs.
      def find_task
        @task = TASKS.find { |task| task[:id] == params[:id].to_i }

        render(json: { error: "Not Found" }, status: :not_found) unless @task
      end

      def task_params
        params.require(:task).permit(:title, :priority, :status).to_h.symbolize_keys
      end
    end
  end
end

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :customers, only: %i[index show create]
      resources :users, only: %i[index show create]
      resources :tasks, except: %i[new edit] do
        post :complete, on: :member
      end
    end
  end
end
