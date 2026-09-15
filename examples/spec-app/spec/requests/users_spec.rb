# frozen_string_literal: true

# Ordinary request specs. As with Minitest, nothing here mentions Reqcord.
require "spec_helper"

RSpec.describe "Users", type: :request do
  let(:auth) { { "Authorization" => "Bearer eyJhbGciOiJIUzI1NiJ9.super-secret" } }

  it "lists users" do
    get "/api/v1/users", params: { per_page: 1 }, headers: auth, as: :json

    expect(response.status).to eq(200)
  end

  it "shows user" do
    get "/api/v1/users/1", headers: auth, as: :json

    expect(response.status).to eq(200)
  end

  it "returns not found for an unknown user" do
    get "/api/v1/users/999", headers: auth, as: :json

    expect(response.status).to eq(404)
  end

  it "creates an active user" do
    post "/api/v1/users",
         params: { user: { name: "Ada Lovelace", email: "ada@example.com", status: "active" } },
         headers: auth,
         as: :json

    expect(response.status).to eq(201)
  end

  it "creates an inactive user" do
    post "/api/v1/users",
         params: { user: { name: "Grace Hopper", email: "grace@example.com", status: "inactive" } },
         headers: auth,
         as: :json

    expect(response.status).to eq(201)
  end

  it "rejects an unknown status" do
    post "/api/v1/users",
         params: { user: { name: "Ada Lovelace", email: "ada@example.com", status: "passive" } },
         headers: auth,
         as: :json

    expect(response.status).to eq(422)
  end

  it "rejects a user without an email" do
    post "/api/v1/users",
         params: { user: { name: "Ada Lovelace", email: "", status: "active" } },
         headers: auth,
         as: :json

    expect(response.status).to eq(422)
  end

  it "requires authentication" do
    get "/api/v1/users", as: :json

    expect(response.status).to eq(401)
  end
end
