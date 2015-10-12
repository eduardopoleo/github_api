module Reports
  module Middleware
    class JasonParser < Faraday::Middleware
      #TODO why I do not require the initialize method in this case
      # def initialize(app)
      #   super(app)
      # end
      def call(env)
        @app.call(env).on_complete do |response_env|
          if response_env.response_headers["content-type"] && response_env.response_headers["content-type"].include?("application/json")
            response_env[:raw_body] = response_env.body
            response_env.body = JSON.parse(response_env.body) if response_env.body.size > 0
          end
        end
      end
    end
  end
end
