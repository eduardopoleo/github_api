module Reports
  module Middleware
    class Cache < Faraday::Middleware
      def initialize(app)
        super(app)
        @app = app
        @storage = {}
      end

      def call(env)
        key = env.url.to_s
        cached_response = @storage[key]
        
        if cached_response && !needs_revalidation?(cached_response)
          return cached_response
        end

        response = @app.call(env)
        response.on_complete do |response_env|
          @storage[key] = response if cachable_response?(response_env)
        end
        response
      end

      def cachable_response?(env)
        env.method == :get && env.response_headers['Cache-Control'] && !env.response_headers['Cache-Control'].include?('no-store')
      end

      def needs_revalidation?(cached_response)
        cached_response.headers['Cache-Control'] == 'no-cache' || cached_response.headers['Cache-Control'] == 'must-revalidate'
      end
    end
  end
end
