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
          if response_cachable?(env)
            @storage[key] = env.response if env.method == :get
          end
        end
      end
      private

      def response_cachable?(env)
        env.method == :get && !has_non_cacheable_headers?(env)
      end

      def has_non_cacheable_headers?(env)
        response_headers = env.response_headers
        cache_codes = ["no-cache", "no-store", "must-revalidate"]
        response_headers.empty? || cache_codes.any? {|code| response_headers["Cache-Control"].include?(code)}
      end
    end
  end
end
