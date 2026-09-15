# frozen_string_literal: true

require_relative "../../app"
require "minitest/autorun"

class HomeAndAuthTest < ActionDispatch::IntegrationTest
  def auth
    { "Authorization" => "Bearer eyJhbGciOiJIUzI1NiJ9.super-secret" }
  end

  test "root describes the api" do
    get "/api/v1", as: :json

    assert_response :ok
  end

  # A form post, not JSON: the documentation must keep it a form.
  test "logs in with a form" do
    post "/api/v1/auth/login", params: { email: "ada@example.com", password: "correct-horse-battery" }

    assert_response :ok
  end

  test "rejects a wrong password" do
    post "/api/v1/auth/login", params: { email: "ada@example.com", password: "wrong" }

    assert_response :unauthorized
  end

  test "shows the profile" do
    get "/api/v1/profile", headers: auth, as: :json

    assert_response :ok
  end

  test "updates the profile" do
    patch "/api/v1/profile", params: { profile: { name: "Ada L.", locale: "tr" } }, headers: auth, as: :json

    assert_response :ok
  end

  test "rejects an unknown locale" do
    patch "/api/v1/profile", params: { profile: { locale: "xx" } }, headers: auth, as: :json

    assert_response :unprocessable_entity
  end

  test "profile requires authentication" do
    get "/api/v1/profile", as: :json

    assert_response :unauthorized
  end
end
