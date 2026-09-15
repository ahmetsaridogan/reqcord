# frozen_string_literal: true

# The host application's own test suite. Reqcord runs this file in a
# subprocess; nothing in it knows that Reqcord exists.
require_relative "app_boot"
require "minitest/autorun"

class CustomersTest < ActionDispatch::IntegrationTest
  def auth
    {
      "Authorization" => "Bearer eyJhbGciOiJIUzI1NiJ9.secret-token",
      "X-Account-Id" => "42"
    }
  end

  test "creates customer" do
    post "/api/v2/customers",
         params: { customer: { name: "John Doe", email: "john@example.com", password: "hunter2" } },
         headers: auth,
         as: :json

    assert_response :created
  end

  test "requires authentication" do
    post "/api/v2/customers", params: { customer: { name: "John Doe" } }, as: :json

    assert_response :unauthorized
  end

  test "rejects duplicate email" do
    post "/api/v2/customers",
         params: { customer: { name: "John Doe", email: "taken@example.com" } },
         headers: auth,
         as: :json

    assert_response :unprocessable_entity
  end

  test "lists customers" do
    get "/api/v2/customers", params: { page: 2 }, headers: auth, as: :json

    assert_response :ok
  end

  test "shows customer" do
    get "/api/v2/customers/42", headers: auth, as: :json

    assert_response :ok
  end
end

# Everything that is not a plain `resources` route.
class OtherRoutesTest < ActionDispatch::IntegrationTest
  test "root" do
    get "/api", as: :json

    assert_response :ok
  end

  test "echo answers get" do
    get "/api/echo", params: { q: "hi" }, as: :json

    assert_response :ok
  end

  test "echo answers post" do
    post "/api/echo", params: { message: "hi" }, as: :json

    assert_response :ok
  end

  test "anything answers get" do
    get "/api/anything", as: :json

    assert_response :ok
  end

  test "shows the cart" do
    get "/api/cart", as: :json

    assert_response :ok
  end

  test "updates the cart with a form body" do
    patch "/api/cart", params: { cart: { coupon: "SAVE10" } }

    assert_response :ok
  end

  test "lists items without an id" do
    get "/api/items", as: :json

    assert_response :ok
  end

  test "shows an item with an id" do
    get "/api/items/9", as: :json

    assert_response :ok
  end

  test "serves a file by glob path" do
    get "/api/files/reports/2026/summary.pdf", as: :json

    assert_response :ok
  end

  test "lists admin customers" do
    get "/api/admin/customers", as: :json

    assert_response :ok
  end

  test "lists billing invoices from the engine" do
    get "/api/billing/invoices", as: :json

    assert_response :ok
  end
end
