# frozen_string_literal: true

require_relative "test_helper"

class DatasetTest < Minitest::Test
  include Reqcord::TestHelpers

  def endpoint(action: "create", method: "POST", path: "/api/v1/customers")
    Reqcord::Endpoint.new(
      method: method,
      path: path,
      controller: "api/v1/customers",
      action: action
    )
  end

  def request_example(**overrides)
    Reqcord::RequestExample.new(**{ method: "POST", path: "/api/v1/customers" }.merge(overrides))
  end

  def test_serializes_multiple_response_examples
    subject = endpoint

    subject.add_exchange(
      request: request_example,
      response: Reqcord::ResponseExample.new(name: "Created", status: 201, body: { "id" => 1 })
    )

    subject.add_exchange(
      request: request_example(body: { "email" => "taken" }),
      response: Reqcord::ResponseExample.new(name: "Duplicate email", status: 422, body: { "errors" => {} })
    )

    responses = Reqcord::Dataset.new(endpoints: [subject])
                                .to_h
                                .fetch(:endpoints)
                                .first
                                .fetch(:response_examples)

    assert_equal 2, responses.size
    assert_equal [201, 422], responses.map { |response| response[:status] }
  end

  # The pair carries the status; a caller of the public API must not have to
  # set it on the request by hand for the endpoint to count as documented.
  def test_add_exchange_backfills_the_request_status
    subject = endpoint
    request = request_example

    subject.add_exchange(request: request, response: Reqcord::ResponseExample.new(status: 201))

    assert_equal 201, request.response_status
    assert subject.curl_ready?
  end

  def test_identical_exchanges_are_stored_once
    subject = endpoint

    2.times do
      subject.add_exchange(
        request: request_example(body: { "name" => "John" }),
        response: Reqcord::ResponseExample.new(status: 201, body: { "id" => 1 })
      )
    end

    assert_equal 1, subject.request_examples.size
    assert_equal 1, subject.response_examples.size
  end

  # After sanitization a wrong and a right password read the same; whichever
  # test ran first must not decide whether the endpoint counts as covered.
  def test_the_same_request_with_a_different_status_is_kept
    subject = endpoint(action: "login", path: "/api/v1/auth/login")
    body = { "email" => "ada@example.com", "password" => "{{password}}" }

    subject.add_exchange(request: request_example(body: body), response: Reqcord::ResponseExample.new(status: 401))
    subject.add_exchange(request: request_example(body: body), response: Reqcord::ResponseExample.new(status: 200))

    assert_equal 2, subject.request_examples.size
    assert subject.curl_ready?
    assert_equal 200, subject.primary_request_example.response_status
  end

  def test_groups_endpoints_into_resources
    dataset = Reqcord::Dataset.new(
      endpoints: [
        endpoint(action: "index", method: "GET"),
        Reqcord::Endpoint.new(method: "GET", path: "/api/v1/surveys", controller: "api/v1/surveys", action: "index")
      ]
    )

    assert_equal %w[api/v1/customers api/v1/surveys], dataset.resources.map(&:name)
    assert_equal %w[Customers Surveys], dataset.resources.map(&:title)
    assert_equal "api/v1", dataset.resources.first.namespace
  end

  def test_resources_are_distinguished_by_namespace
    dataset = Reqcord::Dataset.new(
      endpoints: [
        Reqcord::Endpoint.new(method: "GET", path: "/admin/customers", controller: "admin/customers", action: "index"),
        endpoint(action: "index", method: "GET")
      ]
    )

    assert_equal %w[admin/customers api/v1/customers], dataset.resources.map(&:name)
    assert_equal %w[Customers Customers], dataset.resources.map(&:title)
    assert_equal %w[admin/customers api/v1/customers], dataset.resources.map(&:slug)
  end

  def test_file_basenames_tell_shared_actions_apart_by_verb
    echo = %w[GET POST].map do |method|
      Reqcord::Endpoint.new(method: method, path: "/api/echo", controller: "api/echo", action: "any")
    end
    list = Reqcord::Endpoint.new(method: "GET", path: "/api/echo/all", controller: "api/echo", action: "index")

    basenames = Reqcord::Dataset.new(endpoints: [*echo, list]).resources.first.file_basenames

    assert_equal %w[any-get any-post list], basenames.values.sort
  end

  def test_patch_and_put_twins_fold_into_the_captured_verb
    patch = Reqcord::Endpoint.new(method: "PATCH", path: "/api/cart", controller: "api/carts", action: "update")
    put = Reqcord::Endpoint.new(method: "PUT", path: "/api/cart", controller: "api/carts", action: "update")
    put.add_exchange(
      request: Reqcord::RequestExample.new(method: "PUT", path: "/api/cart", body: { "cart" => { "coupon" => "X" } }),
      response: Reqcord::ResponseExample.new(status: 200, body: { "coupon" => "X" })
    )

    folded = Reqcord::Dataset.fold_method_twins([patch, put])

    assert_equal [put], folded
    assert_equal ["PATCH"], put.also_methods
    assert put.curl_ready?
  end

  def test_patch_wins_when_neither_twin_was_captured
    patch = Reqcord::Endpoint.new(method: "PATCH", path: "/api/cart", controller: "api/carts", action: "update")
    put = Reqcord::Endpoint.new(method: "PUT", path: "/api/cart", controller: "api/carts", action: "update")

    folded = Reqcord::Dataset.fold_method_twins([patch, put])

    assert_equal [patch], folded
    assert_equal ["PUT"], patch.also_methods
  end

  def test_curl_ready_endpoints_require_a_successful_request
    covered = endpoint
    covered.add_exchange(
      request: request_example(response_status: 201),
      response: Reqcord::ResponseExample.new(status: 201)
    )

    error_only = endpoint(action: "index", method: "GET")
    error_only.add_exchange(
      request: Reqcord::RequestExample.new(method: "GET", path: "/api/v1/customers", response_status: 401),
      response: Reqcord::ResponseExample.new(status: 401)
    )

    dataset = Reqcord::Dataset.new(endpoints: [covered, error_only])

    assert_equal [covered], dataset.curl_ready_endpoints
    assert_equal [error_only], dataset.uncovered_endpoints
    refute dataset.empty?
  end

  def test_writes_pretty_json_with_a_schema_version
    Dir.mktmpdir do |directory|
      covered = endpoint
      covered.add_exchange(
        request: request_example(response_status: 201),
        response: Reqcord::ResponseExample.new(status: 201)
      )

      path = Reqcord::Dataset.new(endpoints: [covered, endpoint(action: "index", method: "GET")]).write(File.join(directory, "nested", "dataset.json"))
      data = JSON.parse(File.read(path))

      assert_equal 2, data["schema_version"]
      assert_equal "Create Customer", data.dig("endpoints", 0, "name")
      assert_equal 1, data.fetch("uncovered_routes").size
      refute data.fetch("uncovered_routes").first.key?("request_examples")
    end
  end

  # Every exporter should read the same description of a response: fields
  # inferred from every body seen with that status, plus one example.
  def test_responses_carry_a_schema_per_status
    subject = endpoint

    subject.add_exchange(
      request: request_example,
      response: Reqcord::ResponseExample.new(status: 201, body: { "id" => 1, "name" => "Ada" })
    )
    subject.add_exchange(
      request: request_example(body: { "email" => "" }),
      response: Reqcord::ResponseExample.new(status: 422, body: { "errors" => { "email" => ["can't be blank"] } })
    )

    responses = subject.to_h.fetch(:responses)

    assert_equal [201, 422], responses.map { |response| response[:status] }

    created = responses.first

    assert_equal({ "id" => 1, "name" => "Ada" }, created[:example])
    assert_equal %w[id name], created[:schema].map { |field| field[:path] }
    assert_equal "integer", created[:schema].first[:type]
    assert_equal ["errors.email[]"], responses.last[:schema].map { |field| field[:path] }
  end

  def test_from_h_ignores_unknown_keys
    request = Reqcord::RequestExample.from_h(request_example.to_h.merge("added_later" => 1))
    response = Reqcord::ResponseExample.from_h({ "status" => 200, "added_later" => true })

    assert_equal "POST", request.method
    assert_equal 200, response.status
  end

  def test_a_payload_of_empty_containers_is_not_a_body
    refute request_example(body: { "experience" => {} }).body?
    refute request_example(body: { "a" => nil, "b" => [] }).body?
    assert request_example(body: { "a" => false }).body?
    assert request_example(body: { "experience" => { "name" => "Safari" } }).body?
  end

  def test_examples_round_trip_through_a_hash
    original = request_example(headers: { "X-Account-Id" => "42" }, body: { "name" => "John" })
    copy = Reqcord::RequestExample.from_h(original.to_h)

    assert_equal original.to_h, copy.to_h
  end
end
