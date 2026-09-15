# frozen_string_literal: true

require_relative "../../app"
require "minitest/autorun"

class CartTest < ActionDispatch::IntegrationTest
  def auth
    { "Authorization" => "Bearer eyJhbGciOiJIUzI1NiJ9.super-secret" }
  end

  test "shows the cart" do
    get "/api/v1/cart", headers: auth, as: :json

    assert_response :ok
  end

  test "adds an item to the cart" do
    post "/api/v1/cart/items", params: { item: { sku: "TEA-002", quantity: 3 } }, headers: auth, as: :json

    assert_response :created
  end

  test "rejects an unknown sku" do
    post "/api/v1/cart/items", params: { item: { sku: "TEA-999", quantity: 1 } }, headers: auth, as: :json

    assert_response :unprocessable_entity
  end

  test "removes an item from the cart" do
    delete "/api/v1/cart/items/TEA-001", headers: auth, as: :json

    assert_response :no_content
  end

  test "cannot remove an item that is not in the cart" do
    delete "/api/v1/cart/items/MUG-002", headers: auth, as: :json

    assert_response :not_found
  end

  test "checks out with a card" do
    post "/api/v1/cart/checkout", params: { payment_method: "card" }, headers: auth, as: :json

    assert_response :created
  end

  test "checks out with a bank transfer" do
    post "/api/v1/cart/checkout", params: { payment_method: "bank_transfer" }, headers: auth, as: :json

    assert_response :created
  end

  test "rejects an unknown payment method" do
    post "/api/v1/cart/checkout", params: { payment_method: "cash" }, headers: auth, as: :json

    assert_response :unprocessable_entity
  end

  test "cart requires authentication" do
    get "/api/v1/cart", as: :json

    assert_response :unauthorized
  end
end
