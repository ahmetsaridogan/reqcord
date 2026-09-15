# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Orders", type: :request do
  let(:auth) { { "Authorization" => "Bearer eyJhbGciOiJIUzI1NiJ9.super-secret" } }

  let(:order_payload) do
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

  it "lists orders" do
    get "/api/v1/orders", headers: auth, as: :json

    expect(response.status).to eq(200)
  end

  it "lists pending orders" do
    get "/api/v1/orders", params: { status: "pending" }, headers: auth, as: :json

    expect(response.status).to eq(200)
  end

  it "lists shipped orders" do
    get "/api/v1/orders", params: { status: "shipped" }, headers: auth, as: :json

    expect(response.status).to eq(200)
  end

  it "shows an order" do
    get "/api/v1/orders/1", headers: auth, as: :json

    expect(response.status).to eq(200)
  end

  it "hides another customer's order" do
    get "/api/v1/orders/3", headers: auth, as: :json

    expect(response.status).to eq(403)
  end

  it "returns not found for an unknown order" do
    get "/api/v1/orders/999", headers: auth, as: :json

    expect(response.status).to eq(404)
  end

  it "creates an order" do
    post "/api/v1/orders", params: order_payload, headers: auth, as: :json

    expect(response.status).to eq(201)
  end

  it "creates a single item order" do
    post "/api/v1/orders",
         params: { order: { line_items: [{ sku: "MUG-002", quantity: 1 }], shipping_address: { line1: "Piazza", city: "Rome", country: "IT" } } },
         headers: auth,
         as: :json

    expect(response.status).to eq(201)
  end

  it "rejects an order without line items" do
    post "/api/v1/orders", params: { order: { line_items: [] } }, headers: auth, as: :json

    expect(response.status).to eq(422)
  end

  it "rejects an unknown sku" do
    post "/api/v1/orders", params: { order: { line_items: [{ sku: "TEA-999", quantity: 1 }] } }, headers: auth, as: :json

    expect(response.status).to eq(422)
  end

  it "cancels a pending order" do
    post "/api/v1/orders/1/cancel", headers: auth, as: :json

    expect(response.status).to eq(200)
  end

  it "cannot cancel a shipped order" do
    post "/api/v1/orders/2/cancel", headers: auth, as: :json

    expect(response.status).to eq(409)
  end

  it "deletes an order" do
    delete "/api/v1/orders/1", headers: auth, as: :json

    expect(response.status).to eq(204)
  end

  it "orders require authentication" do
    get "/api/v1/orders", as: :json

    expect(response.status).to eq(401)
  end

  it "lists the notes of an order" do
    get "/api/v1/orders/1/notes", headers: auth, as: :json

    expect(response.status).to eq(200)
  end

  it "adds a note to an order" do
    post "/api/v1/orders/1/notes", params: { note: { body: "Ring the bell twice" } }, headers: auth, as: :json

    expect(response.status).to eq(201)
  end

  it "rejects an empty note" do
    post "/api/v1/orders/1/notes", params: { note: { body: "" } }, headers: auth, as: :json

    expect(response.status).to eq(422)
  end
end
