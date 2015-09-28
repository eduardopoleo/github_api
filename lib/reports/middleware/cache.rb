module Reports
  module Middleware
    class Cache < Faraday::Middleware
      def initialize(app, storage)
        super(app)
        @app = app
        @storage = storage # storage was passed as an argument on the faraday stack.
      end

      def call(env)
        key = env.url.to_s
        cached_response = @storage.read(key)
        # Abstracts away the idea of memory. In order to prepare for memcache and redis

        if cached_response # checks if there's a cached response
          if fresh?(cached_response) # checks that the response is not stale meaning that it does not exceeds the max-age
            if !needs_revalidation?(cached_response)
              cached_response.env.response_headers["X-Faraday-Cache-Status"] = "true"
              return cached_response
            end
          else
            # if not fresh, compare the Etag to check whether or not the content has changed
            # this will happen on the call
            env.request_headers["If-None-Match"] = cached_response.headers['ETag']
          end
        end

        response = @app.call(env)
        response.on_complete do |response_env|
          if cachable_response?(response_env) #checks for method :get and "no-store"
            if response.status == 304 # Not Modified. This always means that the response has not changed
              cached_response = @storage.read(key) # Is this necessary ?
              cached_response.headers['Date'] = response.headers['Date'] #Re updates the date of the cache for future max-age checks
              @storage.write(key, cached_response)# re caches the response with updated date

              response.env.update(cached_response.env) # How does this work? and what does it do?
            else
              @storage.write(key, response) #If the response has been modifed then re cached the new response
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

      # from here onwards it is just to check that the response is not stale
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
