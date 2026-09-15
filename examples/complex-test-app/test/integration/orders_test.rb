# frozen_string_literal: true

require_relative "../../app"
require "minitest/autorun"

class OrdersTest < ActionDispatch::IntegrationTest
  def auth
    { "Authorization" => "Bearer eyJhbGciOiJIUzI1NiJ9.super-secret" }
  end

  def order_payload
    {
      order: {
        line_items: [
          { sku: "TEA-001", quantity: 2 },
          { sku: "MUG-001", quantity: 1 }
        ],
        shipping_address: { line1: "1 Analytical Engine Way", city: "London", country: "GB" }
      }
    }
  end

  test "lists orders" do
    get "/api/v1/orders", headers: auth, as: :json

    assert_response :ok
  end

  test "lists pending orders" do
    get "/api/v1/orders", params: { status: "pending" }, headers: auth, as: :json

    assert_response :ok
  end

  test "lists shipped orders" do
    get "/api/v1/orders", params: { status: "shipped" }, headers: auth, as: :json

    assert_response :ok
  end

  test "shows an order" do
    get "/api/v1/orders/1", headers: auth, as: :json

    assert_response :ok
  end

  test "hides another customer's order" do
    get "/api/v1/orders/3", headers: auth, as: :json

    assert_response :forbidden
  end

  test "returns not found for an unknown order" do
    get "/api/v1/orders/999", headers: auth, as: :json

    assert_response :not_found
  end

  test "creates an order" do
    post "/api/v1/orders", params: order_payload, headers: auth, as: :json

    assert_response :created
  end

  test "creates a single item order" do
    post "/api/v1/orders",
         params: { order: { line_items: [{ sku: "MUG-002", quantity: 1 }], shipping_address: { line1: "Piazza", city: "Rome", country: "IT" } } },
         headers: auth,
         as: :json

    assert_response :created
  end

  test "rejects an order without line items" do
    post "/api/v1/orders", params: { order: { line_items: [] } }, headers: auth, as: :json

    assert_response :unprocessable_entity
  end

  test "rejects an unknown sku" do
    post "/api/v1/orders", params: { order: { line_items: [{ sku: "TEA-999", quantity: 1 }] } }, headers: auth, as: :json

    assert_response :unprocessable_entity
  end

  test "cancels a pending order" do
    post "/api/v1/orders/1/cancel", headers: auth, as: :json

    assert_response :ok
  end

  test "cannot cancel a shipped order" do
    post "/api/v1/orders/2/cancel", headers: auth, as: :json

    assert_response :conflict
  end

  test "deletes an order" do
    delete "/api/v1/orders/1", headers: auth, as: :json

    assert_response :no_content
  end

  test "orders require authentication" do
    get "/api/v1/orders", as: :json

    assert_response :unauthorized
  end

  test "lists the notes of an order" do
    get "/api/v1/orders/1/notes", headers: auth, as: :json

    assert_response :ok
  end

  test "adds a note to an order" do
    post "/api/v1/orders/1/notes", params: { note: { body: "Ring the bell twice" } }, headers: auth, as: :json

    assert_response :created
  end

  test "rejects an empty note" do
    post "/api/v1/orders/1/notes", params: { note: { body: "" } }, headers: auth, as: :json

    assert_response :unprocessable_entity
  end
end
