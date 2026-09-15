# frozen_string_literal: true

require_relative "../../app"
require "minitest/autorun"

class AdminTest < ActionDispatch::IntegrationTest
  def api_key
    { "X-Api-Key" => "sk_live_super-secret-key" }
  end

  test "admin lists products with costs" do
    get "/api/v1/admin/products", headers: api_key, as: :json

    assert_response :ok
  end

  test "admin requires an api key" do
    get "/api/v1/admin/products", as: :json

    assert_response :unauthorized
  end

  test "admin creates a product" do
    post "/api/v1/admin/products",
         params: { product: { sku: "TEA-003", name: "Jasmine", category: "tea", price_cents: 1400 } },
         headers: api_key,
         as: :json

    assert_response :created
  end

  test "admin rejects a product without a sku" do
    post "/api/v1/admin/products", params: { product: { sku: "", name: "Nameless" } }, headers: api_key, as: :json

    assert_response :unprocessable_entity
  end

  test "admin rejects a duplicate sku" do
    post "/api/v1/admin/products",
         params: { product: { sku: "TEA-001", name: "Earl Grey again", category: "tea", price_cents: 1200 } },
         headers: api_key,
         as: :json

    assert_response :conflict
  end

  test "admin deletes a product" do
    delete "/api/v1/admin/products/4", headers: api_key, as: :json

    assert_response :no_content
  end

  test "admin cannot delete an unknown product" do
    delete "/api/v1/admin/products/999", headers: api_key, as: :json

    assert_response :not_found
  end

  test "v2 lists products" do
    get "/api/v2/products", as: :json

    assert_response :ok
  end

  test "v2 follows a cursor" do
    get "/api/v2/products", params: { cursor: "eyJpZCI6Mn0" }, as: :json

    assert_response :ok
  end
end
