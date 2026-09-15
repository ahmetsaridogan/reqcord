# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Cart", type: :request do
  let(:auth) { { "Authorization" => "Bearer eyJhbGciOiJIUzI1NiJ9.super-secret" } }

  it "shows the cart" do
    get "/api/v1/cart", headers: auth, as: :json

    expect(response.status).to eq(200)
  end

  it "adds an item to the cart" do
    post "/api/v1/cart/items", params: { item: { sku: "TEA-002", quantity: 3 } }, headers: auth, as: :json

    expect(response.status).to eq(201)
  end

  it "rejects an unknown sku" do
    post "/api/v1/cart/items", params: { item: { sku: "TEA-999", quantity: 1 } }, headers: auth, as: :json

    expect(response.status).to eq(422)
  end

  it "removes an item from the cart" do
    delete "/api/v1/cart/items/TEA-001", headers: auth, as: :json

    expect(response.status).to eq(204)
  end

  it "cannot remove an item that is not in the cart" do
    delete "/api/v1/cart/items/MUG-002", headers: auth, as: :json

    expect(response.status).to eq(404)
  end

  it "checks out with a card" do
    post "/api/v1/cart/checkout", params: { payment_method: "card" }, headers: auth, as: :json

    expect(response.status).to eq(201)
  end

  it "checks out with a bank transfer" do
    post "/api/v1/cart/checkout", params: { payment_method: "bank_transfer" }, headers: auth, as: :json

    expect(response.status).to eq(201)
  end

  it "rejects an unknown payment method" do
    post "/api/v1/cart/checkout", params: { payment_method: "cash" }, headers: auth, as: :json

    expect(response.status).to eq(422)
  end

  it "cart requires authentication" do
    get "/api/v1/cart", as: :json

    expect(response.status).to eq(401)
  end
end
