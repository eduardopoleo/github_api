require "faraday"
require "reports/middleware/cache"

module Reports::Middleware
  RSpec.describe Cache do
    let(:stubs) { Faraday::Adapter::Test::Stubs.new }

    let(:conn) do
      Faraday.new do |builder|
        builder.use Cache
        builder.adapter :test, stubs
      end
    end

    it "returns a previously cached response" do
      stubs.get("http://example.test") { [200, {}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eql(200)
    end

    %w{post patch put}.each do |http_method|
      it "does not cache #{http_method} requests" do
        stubs.send(http_method, "http://example.test") { [200, {}, "hello"] }
        conn.send(http_method, "http://example.test")
        stubs.send(http_method, "http://example.test") { [404, {}, "not found"] }

        response = conn.send(http_method, "http://example.test")
        expect(response.status).to eql(404)
      end
    end
  end
end
