# frozen_string_literal: true

require_relative "test_helper"

class EndpointTest < Minitest::Test
  include Reqcord::TestHelpers

  def endpoint(action:, method: "GET", path: "/api/v2/customers", controller: "api/v2/customers")
    Reqcord::Endpoint.new(method: method, path: path, controller: controller, action: action)
  end

  def test_titles_are_derived_from_action_and_resource
    assert_equal "List Customers", endpoint(action: "index").name
    assert_equal "Get Customer", endpoint(action: "show").name
    assert_equal "Create Customer", endpoint(action: "create", method: "POST").name
    assert_equal "Delete Customer", endpoint(action: "destroy", method: "DELETE").name
    assert_equal "Activate Customer",
                 endpoint(action: "activate", method: "POST", path: "/api/v2/customers/:id/activate").name
  end

  def test_custom_actions_are_titled_from_their_own_name
    # A member route talks about one record, a collection route about many.
    assert_equal "Activate Customer",
                 endpoint(action: "activate", method: "POST", path: "/api/v2/customers/:id/activate").name

    assert_equal "Search Customers",
                 endpoint(action: "search", method: "POST", path: "/api/v2/customers/search").name
  end

  def test_a_nested_collection_is_not_a_member_route
    nested = Reqcord::Endpoint.new(
      method: "POST",
      path: "/api/v2/customers/:customer_id/surveys/export",
      controller: "api/v2/surveys",
      action: "export"
    )

    assert_equal "Export Surveys", nested.name
    refute nested.member?
  end

  def test_new_and_edit_are_known_actions
    assert_equal "New Customer", endpoint(action: "new", path: "/api/v2/customers/new").name
    assert_equal "Edit Customer", endpoint(action: "edit", path: "/api/v2/customers/:id/edit").name
  end

  def test_an_already_plural_resource_is_not_pluralized_twice
    assert_equal "List Customers", endpoint(action: "index").name
  end

  def test_resource_falls_back_to_the_controller
    assert_equal "customers", endpoint(action: "index").resource
  end

  def test_path_params_come_from_the_route_pattern
    subject = endpoint(action: "index", path: "/api/v2/customers/:customer_id/surveys")

    assert_equal ["customer_id"], subject.path_params
  end

  def test_path_params_include_globs_and_optional_segments
    assert_equal ["path"], endpoint(action: "show", path: "/api/files/*path", controller: "api/files").path_params
    assert_equal ["id"], endpoint(action: "show", path: "/api/items(/:id)", controller: "api/items").path_params
  end

  def test_optional_and_glob_segments_do_not_make_a_member_route
    refute endpoint(action: "show", path: "/api/items(/:id)", controller: "api/items").member?
    refute endpoint(action: "show", path: "/api/files/*path", controller: "api/files").member?
    assert endpoint(action: "show", path: "/api/v2/customers/:id").member?
  end

  def test_a_singular_resource_addresses_one_record
    checkout = endpoint(action: "checkout", method: "POST", path: "/api/v1/cart/checkout", controller: "api/v1/carts")

    assert checkout.member?
    assert_equal "Checkout Cart", checkout.name
    assert_equal "Delete Cart Item",
                 endpoint(action: "destroy", method: "DELETE", path: "/api/v1/cart/items/:sku", controller: "api/v1/cart_items").name
  end

  def test_custom_actions_on_singular_controllers_are_titled_by_the_action
    assert_equal "Login", endpoint(action: "login", method: "POST", path: "/api/v1/auth/login", controller: "api/v1/auth").name
    assert_equal "Refresh Session", endpoint(action: "refresh", method: "POST", path: "/api/v1/session/renew", controller: "api/v1/session").name
    assert_equal "Search Products", endpoint(action: "search", path: "/api/v1/products/search", controller: "api/v1/products").name
  end

  def test_routes_that_do_not_name_their_resource_are_titled_as_pages
    assert_equal "Home", endpoint(action: "index", path: "/api", controller: "api/home").name
    assert_equal "Home", endpoint(action: "index", path: "/", controller: "home").name
    assert_equal "Get Health", endpoint(action: "show", path: "/health", controller: "health").name
    assert_equal "Update Cart", endpoint(action: "update", method: "PATCH", path: "/api/cart", controller: "api/carts").name
  end

  def test_the_leading_example_is_one_that_succeeded
    subject = endpoint(action: "create", method: "POST")

    failed = Reqcord::RequestExample.new(method: "POST", path: "/api/v2/customers", body: { "a" => 1 }, response_status: 422)
    succeeded = Reqcord::RequestExample.new(method: "POST", path: "/api/v2/customers", body: { "b" => 2 }, response_status: 201)

    subject.add_exchange(request: failed, response: Reqcord::ResponseExample.new(status: 422))
    subject.add_exchange(request: succeeded, response: Reqcord::ResponseExample.new(status: 201))

    assert_same succeeded, subject.primary_request_example
    assert_equal [succeeded], subject.successful_request_examples
    assert_equal [succeeded], subject.documented_request_examples
  end


  def test_primary_request_is_nil_when_only_error_cases_exist
    subject = endpoint(action: "create", method: "POST")

    rejected = Reqcord::RequestExample.new(
      method: "POST",
      path: "/api/v2/customers",
      response_status: 422,
      body: { "customer" => { "email" => "taken@example.com" } }
    )

    subject.add_request_example(rejected)

    assert_nil subject.primary_request_example
    refute subject.curl_ready?
  end

  # Two accepted requests sent "active" and "passive"; the rejected one sent
  # "inactive" and must leave no trace in what the endpoint is said to take.
  def test_schemas_come_only_from_successful_requests
    subject = endpoint(action: "create", method: "POST")

    [["active", 201], ["passive", 201], ["inactive", 422]].each do |status, code|
      subject.add_exchange(
        request: Reqcord::RequestExample.new(method: "POST", path: "/api/v2/customers", body: { "customer" => { "status" => status } }),
        response: Reqcord::ResponseExample.new(status: code)
      )
    end

    field = subject.body_schema["customer.status"]

    assert field.enum?
    assert_equal %w[active passive], field.listed_values
    assert subject.query_schema.empty?
    assert_equal %w[active passive], subject.to_h.dig(:parameters, :body, 0, :values)
  end

  def test_responses_are_grouped_and_ordered_by_status
    subject = endpoint(action: "create", method: "POST")

    [422, 201, 401].each_with_index do |status, index|
      subject.add_exchange(
        request: Reqcord::RequestExample.new(method: "POST", path: "/api/v2/customers", body: { "i" => index }),
        response: Reqcord::ResponseExample.new(status: status, body: { "i" => index })
      )
    end

    assert_equal [201, 401, 422], subject.responses_by_status.keys
  end

  def test_status_text_comes_from_rack
    assert_equal "201 Created", Reqcord::ResponseExample.new(status: 201).title
  end
end

class EndpointPrimarySuccessfulRequestTest < Minitest::Test
  def test_primary_request_prefers_successful_case_over_error_case
    endpoint = Reqcord::Endpoint.new(
      method: "POST",
      path: "/api/v2/customers",
      controller: "api/v2/customers",
      action: "create"
    )

    rejected = Reqcord::RequestExample.new(
      method: "POST",
      path: "/api/v2/customers",
      response_status: 422,
      body: { "customer" => { "email" => "taken@example.com" } }
    )

    accepted = Reqcord::RequestExample.new(
      method: "POST",
      path: "/api/v2/customers",
      response_status: 201,
      body: { "customer" => { "email" => "john@example.com" } }
    )

    endpoint.add_request_example(rejected)
    endpoint.add_request_example(accepted)

    assert_equal accepted, endpoint.primary_request_example
  end
end
