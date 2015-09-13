module Reports
  module Middleware
    class Authentication < Faraday::Middleware
      def initialize(app)
        super(app)
        @token = ENV['GITHUB_TOKEN']
      end

      def call(env)
        env.request_headers["Authorization"] = "token #{@token}"
        @app.call(env).on_complete do |response_env|
          #TODO whats the difference between the env and the response_env
          # env is the entire Faraday abstraction for the request and response
          if response_env.status == 401
            raise AuthenticationFailure, "Authentication Failed. Please set the 'github token' environment variable to a valid github access token"
          end
        end
      end
    end
  end
end
