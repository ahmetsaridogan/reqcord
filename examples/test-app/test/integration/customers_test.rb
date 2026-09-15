# frozen_string_literal: true

# Ordinary Rails integration tests. Nothing here mentions Reqcord: the
# documentation is generated from the requests these tests already make.
require_relative "../../app"
require "minitest/autorun"

class CustomersTest < ActionDispatch::IntegrationTest
  def auth
    { "Authorization" => "Bearer eyJhbGciOiJIUzI1NiJ9.super-secret" }
  end

  test "lists customers" do
    get "/api/v1/customers", params: { per_page: 1 }, headers: auth, as: :json

    assert_response :ok
  end

  test "shows customer" do
    get "/api/v1/customers/1", headers: auth, as: :json

    assert_response :ok
  end

  test "returns not found for an unknown customer" do
    get "/api/v1/customers/999", headers: auth, as: :json

    assert_response :not_found
  end

  test "creates an active customer" do
    post "/api/v1/customers",
         params: { customer: { name: "Ada Lovelace", email: "ada@example.com", status: "active" } },
         headers: auth,
         as: :json

    assert_response :created
  end

  test "creates a passive customer" do
    post "/api/v1/customers",
         params: { customer: { name: "Grace Hopper", email: "grace@example.com", status: "passive" } },
         headers: auth,
         as: :json

    assert_response :created
  end

  test "rejects an unknown status" do
    post "/api/v1/customers",
         params: { customer: { name: "Ada Lovelace", email: "ada@example.com", status: "inactive" } },
         headers: auth,
         as: :json

    assert_response :unprocessable_entity
  end

  test "rejects a customer without an email" do
    post "/api/v1/customers",
         params: { customer: { name: "Ada Lovelace", email: "", status: "active" } },
         headers: auth,
         as: :json

    assert_response :unprocessable_entity
  end

  test "requires authentication" do
    get "/api/v1/customers", as: :json

    assert_response :unauthorized
  end
end
