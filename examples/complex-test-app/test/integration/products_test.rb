# frozen_string_literal: true

require_relative "../../app"
require "minitest/autorun"

class ProductsTest < ActionDispatch::IntegrationTest
  test "lists products" do
    get "/api/v1/products", as: :json

    assert_response :ok
  end

  test "filters products by category" do
    get "/api/v1/products", params: { filter: { category: "tea" } }, as: :json

    assert_response :ok
  end

  test "filters mugs" do
    get "/api/v1/products", params: { filter: { category: "mugs" } }, as: :json

    assert_response :ok
  end

  test "sorts by price ascending" do
    get "/api/v1/products", params: { sort: "price_asc" }, as: :json

    assert_response :ok
  end

  test "sorts by price descending" do
    get "/api/v1/products", params: { sort: "price_desc" }, as: :json

    assert_response :ok
  end

  test "paginates" do
    get "/api/v1/products", params: { page: 2, per_page: 2 }, as: :json

    assert_response :ok
  end

  test "shows a product" do
    get "/api/v1/products/3", as: :json

    assert_response :ok
  end

  test "returns not found for an unknown product" do
    get "/api/v1/products/999", as: :json

    assert_response :not_found
  end

  test "searches products" do
    get "/api/v1/products/search", params: { q: "mug" }, as: :json

    assert_response :ok
  end

  test "search needs a query" do
    get "/api/v1/products/search", as: :json

    assert_response :bad_request
  end
end
