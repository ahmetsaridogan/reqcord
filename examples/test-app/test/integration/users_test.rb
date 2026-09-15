# frozen_string_literal: true

# Ordinary Rails integration tests. Nothing here mentions Reqcord: the
# documentation is generated from the requests these tests already make.
require_relative "../../app"
require "minitest/autorun"

class UsersTest < ActionDispatch::IntegrationTest
  def auth
    { "Authorization" => "Bearer eyJhbGciOiJIUzI1NiJ9.super-secret" }
  end

  test "lists users" do
    get "/api/v1/users", params: { per_page: 1 }, headers: auth, as: :json

    assert_response :ok
  end

  test "shows user" do
    get "/api/v1/users/1", headers: auth, as: :json

    assert_response :ok
  end

  test "returns not found for an unknown user" do
    get "/api/v1/users/999", headers: auth, as: :json

    assert_response :not_found
  end

  test "creates an active user" do
    post "/api/v1/users",
         params: { user: { name: "Ada Lovelace", email: "ada@example.com", status: "active" } },
         headers: auth,
         as: :json

    assert_response :created
  end

  test "creates a inactive user" do
    post "/api/v1/users",
         params: { user: { name: "Grace Hopper", email: "grace@example.com", status: "inactive" } },
         headers: auth,
         as: :json

    assert_response :created
  end

  test "rejects an unknown status" do
    post "/api/v1/users",
         params: { user: { name: "Ada Lovelace", email: "ada@example.com", status: "passive" } },
         headers: auth,
         as: :json

    assert_response :unprocessable_entity
  end

  test "rejects a user without an email" do
    post "/api/v1/users",
         params: { user: { name: "Ada Lovelace", email: "", status: "active" } },
         headers: auth,
         as: :json

    assert_response :unprocessable_entity
  end

  test "requires authentication" do
    get "/api/v1/users", as: :json

    assert_response :unauthorized
  end
end
