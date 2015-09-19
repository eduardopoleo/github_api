module Reports
  module Middleware
    class Cache < Faraday::Middleware
      def initialize(app)
        super(app)
        @storage = {}
      end

      def call(env)
        key = env.url
        return @storage[key] if @storage[key]
        
        @app.call(env).on_complete do
          @storage[key] = env.response if env.method == :get
        end
      end
    end
  end
end
