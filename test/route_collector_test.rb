# frozen_string_literal: true

require_relative "test_helper"

class RouteCollectorTest < Minitest::Test
  include Reqcord::TestHelpers

  def setup
    skip "actionpack is not installed" unless ACTIONPACK_AVAILABLE
  end

  def test_collects_routes_behind_the_configured_prefix
    routes = customer_routes

    assert_includes routes.map(&:path), "/api/v2/customers"
    refute_includes routes.map(&:path), "/health"
  end

  def test_every_verb_is_normalized
    # A plain "GET" must survive: a stray delete("^$") would empty it.
    assert_equal %w[GET POST], customer_routes.map(&:method).uniq.sort
  end

  def test_route_carries_controller_action_and_resource
    route = customer_routes.find { |candidate| candidate.path == "/api/v2/customers/:id" }

    assert_equal "GET", route.method
    assert_equal "api/v2/customers", route.controller
    assert_equal "show", route.action
    assert_equal "customers", route.resource
    assert_equal "v2", route.api_version
  end

  def test_matches_concrete_request_paths
    routes = customer_routes
    show = routes.find { |candidate| candidate.path == "/api/v2/customers/:id" }
    # Nested routes are drawn first, so the collection route is picked by path.
    index = routes.find { |candidate| candidate.path == "/api/v2/customers" && candidate.method == "GET" }

    assert show.matches?("GET", "/api/v2/customers/42")
    refute show.matches?("POST", "/api/v2/customers/42")
    refute index.matches?("GET", "/api/v2/customers/42")
    assert index.matches?("GET", "/api/v2/customers")
  end

  def test_nested_resource_uses_its_own_controller
    route = customer_routes.find { |candidate| candidate.resource == "surveys" }

    assert_equal "/api/v2/customers/:customer_id/surveys", route.path
    assert route.matches?("GET", "/api/v2/customers/42/surveys")
  end

  def test_filters_by_resource
    assert_equal ["customers"], customer_routes(only: ["customers"]).map(&:resource).uniq
  end

  def test_filters_by_version
    assert_empty customer_routes(version: "v1")
    refute_empty customer_routes(version: "v2")
  end

  def test_builds_an_endpoint_per_route
    endpoint = customer_routes.find { |route| route.action == "create" }.endpoint

    assert_equal "POST", endpoint.method
    assert_equal "/api/v2/customers", endpoint.path
    assert_equal "Create Customer", endpoint.name
    refute endpoint.documented?
  end

  # --- beyond `resources` ---------------------------------------------------

  def routes_for(path)
    mixed_routes.select { |route| route.path == path }
  end

  def test_a_multi_verb_match_becomes_one_route_per_verb
    assert_equal %w[GET POST], routes_for("/echo").map(&:method).sort
  end

  def test_via_all_answers_any_verb
    route = routes_for("/anything").single

    assert_equal "ANY", route.method
    assert route.any_verb?
    assert route.matches?("DELETE", "/anything")
    assert route.matches?("GET", "/anything")
  end

  def test_a_mounted_engine_is_walked_with_its_mount_path
    route = routes_for("/billing/invoices").single

    assert_equal "invoices", route.controller
    assert_equal "index", route.action
    assert route.matches?("GET", "/billing/invoices")
    refute route.matches?("GET", "/invoices")
    refute route.matches?("GET", "/billingx/invoices")
  end

  def test_redirects_and_rack_mounts_are_counted_not_dropped_silently
    collector = mixed_collector
    routes = collector.call

    assert_equal({ "redirect" => 1, "mount" => 1 }, collector.skipped)
    assert_equal 2, collector.skipped_count
    refute_includes routes.map(&:path), "/legacy"
    refute_includes routes.map(&:path), "/rack"
  end

  def test_rails_internal_routes_are_dropped
    refute_includes mixed_routes.map(&:path), "/rails/info"
  end

  def test_root_and_singular_resources_are_collected
    assert_equal ["GET"], routes_for("/").map(&:method)
    assert_equal %w[GET PATCH PUT], routes_for("/cart").map(&:method).sort
    assert_equal "carts", routes_for("/cart").first.controller
  end

  def test_optional_segments_and_globs_keep_rails_notation
    assert_equal "/items(/:id)", routes_for("/items(/:id)").single.path
    assert routes_for("/items(/:id)").single.matches?("GET", "/items")
    assert routes_for("/items(/:id)").single.matches?("GET", "/items/9")
    assert routes_for("/files/*path").single.matches?("GET", "/files/a/b.png")
  end

  def test_the_route_name_survives_into_the_endpoint
    route = routes_for("/files/*path").single

    assert_equal "file_download", route.name
    assert_equal "file_download", route.endpoint.route_name
  end

  def test_resource_filter_accepts_the_singular_and_the_controller_path
    assert_equal ["carts"], mixed_routes(only: ["cart"]).map(&:controller).uniq
    assert_equal ["admin/customers"], mixed_routes(only: ["admin/customers"]).map(&:controller).uniq
  end

  def test_prefix_filter_applies_to_mounted_paths
    assert_equal ["/billing/invoices"], mixed_routes(prefix: "/billing").map(&:path)
  end
end
