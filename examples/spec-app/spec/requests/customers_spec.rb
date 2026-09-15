# frozen_string_literal: true

# Ordinary request specs. As with Minitest, nothing here mentions Reqcord.
#
# The status assertions are spelled out because this example runs on plain
# rspec-core; with rspec-rails you would write `have_http_status(:created)`.
require "spec_helper"

RSpec.describe "Customers", type: :request do
  let(:auth) { { "Authorization" => "Bearer eyJhbGciOiJIUzI1NiJ9.super-secret" } }

  it "lists customers" do
    get "/api/v1/customers", params: { per_page: 1 }, headers: auth, as: :json

    expect(response.status).to eq(200)
  end

  it "shows customer" do
    get "/api/v1/customers/1", headers: auth, as: :json

    expect(response.status).to eq(200)
  end

  it "returns not found for an unknown customer" do
    get "/api/v1/customers/999", headers: auth, as: :json

    expect(response.status).to eq(404)
  end

  it "creates an active customer" do
    post "/api/v1/customers",
         params: { customer: { name: "Ada Lovelace", email: "ada@example.com", status: "active" } },
         headers: auth,
         as: :json

    expect(response.status).to eq(201)
  end

  it "creates a passive customer" do
    post "/api/v1/customers",
         params: { customer: { name: "Grace Hopper", email: "grace@example.com", status: "passive" } },
         headers: auth,
         as: :json

    expect(response.status).to eq(201)
  end

  it "rejects an unknown status" do
    post "/api/v1/customers",
         params: { customer: { name: "Ada Lovelace", email: "ada@example.com", status: "inactive" } },
         headers: auth,
         as: :json

    expect(response.status).to eq(422)
  end

  it "rejects a customer without an email" do
    post "/api/v1/customers",
         params: { customer: { name: "Ada Lovelace", email: "", status: "active" } },
         headers: auth,
         as: :json

    expect(response.status).to eq(422)
  end

  it "requires authentication" do
    get "/api/v1/customers", as: :json

    expect(response.status).to eq(401)
  end
end
