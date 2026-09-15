# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/dummy_server"
require "net/http"

# The collection is only worth shipping if Postman could run it. Without
# newman, this walks the generated collection the way Postman would and fires
# every request at the dummy application, expecting the saved 2xx example.
class PostmanReplayTest < Minitest::Test
  include Reqcord::TestHelpers

  def setup
    skip "actionpack is not installed" unless ACTIONPACK_AVAILABLE

    @collection = JSON.parse(File.read(File.join(DummyServer.documentation, "postman", "collection.json")))
  end

  def requests(items)
    items.flat_map { |item| item.key?("item") ? requests(item["item"]) : [item] }
  end

  def test_every_documented_request_replays_with_its_documented_status
    replayed = 0

    requests(@collection["item"]).each do |item|
      expected = item["response"].map { |response| response["code"] }.find { |code| (200..299).cover?(code) }
      next unless expected

      assert_equal expected, replay(item["request"]), "#{item['request']['method']} #{item['request'].dig('url', 'raw')}"
      replayed += 1
    end

    assert_operator replayed, :>=, 12
  end

  def test_the_unauthorized_example_replays_as_unauthorized
    create = requests(@collection["item"]).find { |item| item["name"] == "Create Customer" }
    unauthorized = create["response"].find { |response| response["code"] == 401 }

    assert_equal 401, replay(unauthorized["originalRequest"])
  end

  private

  def replay(request)
    uri = URI(request.dig("url", "raw").gsub("{{base_url}}", DummyServer.base_url).gsub("{{token}}", DummyServer::TOKEN))
    http_request = Net::HTTP.const_get(request["method"].capitalize).new(uri)

    request.fetch("header", []).each do |header|
      http_request[header["key"]] = header["value"].gsub("{{token}}", DummyServer::TOKEN)
    end

    if @collection.dig("auth", "type") == "bearer" && request.dig("auth", "type") != "noauth"
      http_request["Authorization"] = "Bearer #{DummyServer::TOKEN}"
    end

    attach_body(http_request, request["body"])

    Net::HTTP.start(uri.host, uri.port) { |http| http.request(http_request) }.code.to_i
  end

  def attach_body(http_request, body)
    return if body.nil?

    case body["mode"]
    when "raw"
      http_request.body = body["raw"]
      http_request["Content-Type"] ||= "application/json"
    when "urlencoded"
      http_request.set_form_data(body["urlencoded"].to_h { |pair| [pair["key"], pair["value"]] })
    end
  end
end
