# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin and v2", type: :request do
  let(:api_key) { { "X-Api-Key" => "sk_live_super-secret-key" } }

  it "admin lists products with costs" do
    get "/api/v1/admin/products", headers: api_key, as: :json

    expect(response.status).to eq(200)
  end

  it "admin requires an api key" do
    get "/api/v1/admin/products", as: :json

    expect(response.status).to eq(401)
  end

  it "admin creates a product" do
    post "/api/v1/admin/products",
         params: { product: { sku: "TEA-003", name: "Jasmine", category: "tea", price_cents: 1400 } },
         headers: api_key,
         as: :json

    expect(response.status).to eq(201)
  end

  it "admin rejects a product without a sku" do
    post "/api/v1/admin/products", params: { product: { sku: "", name: "Nameless" } }, headers: api_key, as: :json

    expect(response.status).to eq(422)
  end

  it "admin rejects a duplicate sku" do
    post "/api/v1/admin/products",
         params: { product: { sku: "TEA-001", name: "Earl Grey again", category: "tea", price_cents: 1200 } },
         headers: api_key,
         as: :json

    expect(response.status).to eq(409)
  end

  it "admin deletes a product" do
    delete "/api/v1/admin/products/4", headers: api_key, as: :json

    expect(response.status).to eq(204)
  end

  it "admin cannot delete an unknown product" do
    delete "/api/v1/admin/products/999", headers: api_key, as: :json

    expect(response.status).to eq(404)
  end

  def fixture_upload(name)
    Rack::Test::UploadedFile.new(File.expand_path("../fixtures/#{name}", __dir__), "image/png")
  end

  it "admin uploads a product image" do
    post "/api/v1/admin/products/1/image",
         params: { image: fixture_upload("label.png"), alt: "Stoneware mug on a table" },
         headers: api_key

    expect(response.status).to eq(201)
  end

  it "admin cannot upload an image for an unknown product" do
    post "/api/v1/admin/products/999/image", params: { image: fixture_upload("label.png") }, headers: api_key

    expect(response.status).to eq(404)
  end

  it "v2 lists products" do
    get "/api/v2/products", as: :json

    expect(response.status).to eq(200)
  end

  it "v2 follows a cursor" do
    get "/api/v2/products", params: { cursor: "eyJpZCI6Mn0" }, as: :json

    expect(response.status).to eq(200)
  end
end
