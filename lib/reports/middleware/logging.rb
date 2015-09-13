module Reports
  module Middleware
    class Logging < Faraday::Middleware
      def initialize(app)
        super(app)
        @logger = Logger.new(STDOUT)
        @logger.formatter = proc{ |severity, datetime, program, message| message + "\n"}
      end

      def call(env)
        #this method is called before the call was made to the api
        start_time = Time.now

        #This is done after the call
        @app.call(env).on_complete do
          #@app.call(env) yield control over the next stack but .on_complete Makes
          # sure that we run this code after. The response info is on env
          duration = Time.now - start_time
          url, method, status = env.url.to_s, env.method, env.status
          @logger.debug '-> %s %s %d (%.3f s)' % [url, method.to_s.upcase, status, duration]
        end
      end
    end
  end
end
