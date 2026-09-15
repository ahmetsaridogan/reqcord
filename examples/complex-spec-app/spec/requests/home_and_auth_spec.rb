# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Home and auth", type: :request do
  let(:auth) { { "Authorization" => "Bearer eyJhbGciOiJIUzI1NiJ9.super-secret" } }

  it "root describes the api" do
    get "/api/v1", as: :json

    expect(response.status).to eq(200)
  end

  it "logs in with a form" do
    post "/api/v1/auth/login", params: { email: "ada@example.com", password: "correct-horse-battery" }

    expect(response.status).to eq(200)
  end

  it "rejects a wrong password" do
    post "/api/v1/auth/login", params: { email: "ada@example.com", password: "wrong" }

    expect(response.status).to eq(401)
  end

  it "shows the profile" do
    get "/api/v1/profile", headers: auth, as: :json

    expect(response.status).to eq(200)
  end

  it "updates the profile" do
    patch "/api/v1/profile", params: { profile: { name: "Ada L.", locale: "tr" } }, headers: auth, as: :json

    expect(response.status).to eq(200)
  end

  it "rejects an unknown locale" do
    patch "/api/v1/profile", params: { profile: { locale: "xx" } }, headers: auth, as: :json

    expect(response.status).to eq(422)
  end

  it "profile requires authentication" do
    get "/api/v1/profile", as: :json

    expect(response.status).to eq(401)
  end
end
