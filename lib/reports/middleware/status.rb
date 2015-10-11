module Reports
  module Middleware
    class Status < Faraday::Middleware
      VALID_STATUS_CODES = [200, 302, 403, 422, 404, 401, 201]

      def initialize(app)
        super(app)
      end

      def call(env)
        @app.call(env).on_complete do |response_env|
          if !VALID_STATUS_CODES.include?(response_env.status)
            raise RequestFailure, JSON.parse(response_env.body)["message"]
          end

          if response_env.status == 401
            raise AuthenticationFailure, "Authentication Failed please send the correct github token"
          end
        end
      end
    end
  end
end
