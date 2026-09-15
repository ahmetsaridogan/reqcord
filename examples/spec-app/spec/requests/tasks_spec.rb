# frozen_string_literal: true

# Ordinary request specs. As with Minitest, nothing here mentions Reqcord.
require "spec_helper"

RSpec.describe "Tasks", type: :request do
  it "lists tasks" do
    get "/api/v1/tasks", as: :json

    expect(response.status).to eq(200)
  end

  it "lists open tasks" do
    get "/api/v1/tasks", params: { status: "open" }, as: :json

    expect(response.status).to eq(200)
  end

  it "lists done tasks" do
    get "/api/v1/tasks", params: { status: "done" }, as: :json

    expect(response.status).to eq(200)
  end

  it "shows a task" do
    get "/api/v1/tasks/1", as: :json

    expect(response.status).to eq(200)
  end

  it "returns not found for an unknown task" do
    get "/api/v1/tasks/999", as: :json

    expect(response.status).to eq(404)
  end

  it "creates a high priority task" do
    post "/api/v1/tasks", params: { task: { title: "Review the release", priority: "high" } }, as: :json

    expect(response.status).to eq(201)
  end

  it "creates a low priority task" do
    post "/api/v1/tasks", params: { task: { title: "Water the plants", priority: "low" } }, as: :json

    expect(response.status).to eq(201)
  end

  it "rejects a task without a title" do
    post "/api/v1/tasks", params: { task: { title: "", priority: "high" } }, as: :json

    expect(response.status).to eq(422)
  end

  it "rejects an unknown priority" do
    post "/api/v1/tasks", params: { task: { title: "Anything", priority: "urgent" } }, as: :json

    expect(response.status).to eq(422)
  end

  it "updates a task" do
    patch "/api/v1/tasks/1", params: { task: { title: "Write better docs" } }, as: :json

    expect(response.status).to eq(200)
  end

  it "completes a task" do
    post "/api/v1/tasks/1/complete", as: :json

    expect(response.status).to eq(200)
  end

  it "deletes a task" do
    delete "/api/v1/tasks/3", as: :json

    expect(response.status).to eq(204)
  end
end
