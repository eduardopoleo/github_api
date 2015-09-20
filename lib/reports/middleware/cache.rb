module Reports
  module Middleware
    class Cache < Faraday::Middleware
      def initialize(app, storage)
        super(app)
        @app = app
        @storage = storage
      end

      def call(env)
        key = env.url.to_s
        cached_response = @storage.read(key)

        if cached_response
          if fresh?(cached_response)
            return @storage.read(key) if !needs_revalidation?(cached_response)
          else
            env.request_headers["If-None-Match"] = cached_response.headers['ETag']
          end
        end
        response = @app.call(env)
        response.on_complete do |response_env|
          if cachable_response?(response_env)
            if response.status == 304
              cached_response = @storage.read(key)
              cached_response.headers['Date'] = response.headers['Date']
              @storage.write(key, cached_response)

              response.env.update(cached_response.env)
            else
              @storage.write(key, response)
            end
          end
        end
        response
      end

      def cachable_response?(env)
        env.method == :get && env.response_headers['Cache-Control'] && !env.response_headers['Cache-Control'].include?('no-store')
      end

      def needs_revalidation?(cached_response)
        cached_response.headers['Cache-Control'] == 'no-cache' || cached_response.headers['Cache-Control'] == 'must-revalidate'
      end

      def fresh?(cached_response)
        age = cached_response_age(cached_response)
        max_age = cached_response_max_age(cached_response)

        if age && max_age # Always stale without these values
          age <= max_age
        end
      end

      def cached_response_age(cached_response)
        date = cached_response.headers['Date']
        if date
          time = Time.httpdate(date)
          (Time.now - time).floor
        end
      end

      def cached_response_max_age(cached_response)
        cache_control = cached_response.headers['Cache-Control']
        if cache_control
          match = cache_control.match(/max\-age=(\d+)/)
          match[1].to_i if match
        end
      end
    end
  end
end
