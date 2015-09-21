require "time"

module Reports
  module Middleware
    class Cache < Faraday::Middleware
      def initialize(app)
        super(app)
        #Cache is in reality just a storage
        @storage = {}
      end

      def call(env)
        key = env.url
        return @storage[key] if @storage[key]
      # [status, headers, body]
        @app.call(env).on_complete do
           cache_response(env) if response_cachable?(env)
        end
      end

      private

      def cache_response(env)
        key = env.url
        @storage[key] = env.response
      end

      def response_cachable?(env)
        env.method == :get && !needs_revalidation?(env)
      end

      def needs_revalidation?(env)
        headers_prevent_caching?(env) || cache_is_stale?(env)
      end

      def headers_prevent_caching?(env)
        headers = env.response_headers
        cache_codes = ["no-cache", "no-store", "must-revalidate"]
        headers.empty? || cache_codes.any? {|code| headers["Cache-Control"].include?(code)}
      end

      def cache_is_stale?(env)
        headers = env.response_headers
        if headers["Cache-Control"].include? "max-age"
          period = headers["Cache-Control"][/\d+/].to_i
          if (Time.now - Time.httpdate(headers["Date"])) > period
            return true
          else
            return false
          end
        end
      end
    end
  end
end
