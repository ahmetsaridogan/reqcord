# frozen_string_literal: true

# Ordinary Rails integration tests. Nothing here mentions Reqcord: the
# documentation is generated from the requests these tests already make.
require_relative "../../app"
require "minitest/autorun"

class TasksTest < ActionDispatch::IntegrationTest
  test "lists tasks" do
    get "/api/v1/tasks", as: :json

    assert_response :ok
  end

  test "lists open tasks" do
    get "/api/v1/tasks", params: { status: "open" }, as: :json

    assert_response :ok
  end

  test "lists done tasks" do
    get "/api/v1/tasks", params: { status: "done" }, as: :json

    assert_response :ok
  end

  test "shows a task" do
    get "/api/v1/tasks/1", as: :json

    assert_response :ok
  end

  test "returns not found for an unknown task" do
    get "/api/v1/tasks/999", as: :json

    assert_response :not_found
  end

  test "creates a high priority task" do
    post "/api/v1/tasks", params: { task: { title: "Review the release", priority: "high" } }, as: :json

    assert_response :created
  end

  test "creates a low priority task" do
    post "/api/v1/tasks", params: { task: { title: "Water the plants", priority: "low" } }, as: :json

    assert_response :created
  end

  test "rejects a task without a title" do
    post "/api/v1/tasks", params: { task: { title: "", priority: "high" } }, as: :json

    assert_response :unprocessable_entity
  end

  test "rejects an unknown priority" do
    post "/api/v1/tasks", params: { task: { title: "Anything", priority: "urgent" } }, as: :json

    assert_response :unprocessable_entity
  end

  test "updates a task" do
    patch "/api/v1/tasks/1", params: { task: { title: "Write better docs" } }, as: :json

    assert_response :ok
  end

  test "completes a task" do
    post "/api/v1/tasks/1/complete", as: :json

    assert_response :ok
  end

  test "deletes a task" do
    delete "/api/v1/tasks/3", as: :json

    assert_response :no_content
  end
end
