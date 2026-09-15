# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Products", type: :request do
  it "lists products" do
    get "/api/v1/products", as: :json

    expect(response.status).to eq(200)
  end

  it "filters products by category" do
    get "/api/v1/products", params: { filter: { category: "tea" } }, as: :json

    expect(response.status).to eq(200)
  end

  it "filters mugs" do
    get "/api/v1/products", params: { filter: { category: "mugs" } }, as: :json

    expect(response.status).to eq(200)
  end

  it "sorts by price ascending" do
    get "/api/v1/products", params: { sort: "price_asc" }, as: :json

    expect(response.status).to eq(200)
  end

  it "sorts by price descending" do
    get "/api/v1/products", params: { sort: "price_desc" }, as: :json

    expect(response.status).to eq(200)
  end

  it "paginates" do
    get "/api/v1/products", params: { page: 2, per_page: 2 }, as: :json

    expect(response.status).to eq(200)
  end

  it "shows a product" do
    get "/api/v1/products/3", as: :json

    expect(response.status).to eq(200)
  end

  it "returns not found for an unknown product" do
    get "/api/v1/products/999", as: :json

    expect(response.status).to eq(404)
  end

  it "searches products" do
    get "/api/v1/products/search", params: { q: "mug" }, as: :json

    expect(response.status).to eq(200)
  end

  it "search needs a query" do
    get "/api/v1/products/search", as: :json

    expect(response.status).to eq(400)
  end
end
