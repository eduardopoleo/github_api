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
      #stubs.method("url") {[status, {header}, body]}
      stubs.get("http://example.test") { [200, {'Cache-Control' => 'public'}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eql(200)
    end

    %w{post patch put}.each do |http_method|
      it "does not cache #{http_method} requests" do
        #we can use send whe we want to iterate over the an array of methods.
        stubs.send(http_method, "http://example.test") { [200, {'Cache-Control' => 'public'}, "hello"] }
        conn.send(http_method, "http://example.test")
        stubs.send(http_method, "http://example.test") { [404, {}, "not found"] }

        response = conn.send(http_method, "http://example.test")
        expect(response.status).to eql(404)
      end
    end

   it "does not cache when the response doesn't have Cache-Control header" do
      stubs.get("http://example.test") { [200, {}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eql(404)
    end

    it "does not cache when the response Cache-Control header has no-store value" do
      stubs.get("http://example.test") { [200, {'Cache-Control' => 'no-store'}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eql(404)
    end

    it "does not use cached response when the response Cache-Control header has no-cache value" do
      stubs.get("http://example.test") { [200, {'Cache-Control' => 'no-cache'}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eql(404)
    end

    it "does not use cached response when the response Cache-Control header has must-revalidate value" do
      stubs.get("http://example.test") { [200, {'Cache-Control' => 'must-revalidate'}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eql(404)
    end
  end
end
