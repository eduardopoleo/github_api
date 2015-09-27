require 'faraday'
require 'json'
require 'logger'
require_relative 'middleware/logging'
require_relative 'middleware/authentication'
require_relative 'middleware/status'
require_relative 'middleware/json_parser'
require_relative 'middleware/cache'
require_relative 'storage/memory'

module Reports
  class Error < StandardError; end
  class RequestFailure < Error; end
  class NonExistingUser < Error; end
  class AuthenticationFailure < Error; end

  User = Struct.new(:name, :location, :public_repos)
  Repo = Struct.new(:name, :url)

  #Concerns of the client:
  #This could probably be seen as on big concern: Handling Api call.
    # - Set the headers of the response, (this is where the token goes)
    # - Makes the api call, including the auth token
    # - Check and raise response errors
    # - Parse user information
    # - Creates and returns user
  class GitHubAPIClient
    def user_info(username)
      url = "https://api.github.com/users/#{username}"
      response = connection.get(url, nil)
      User.new(response.body["name"], response.body["location"], response.body["public_repos"])
    end

    def repos(username)
      url = "https://api.github.com/users/#{username}/repos"
      response = connection.get(url, nil)
      repos = response.body.map do |repo|
        Repo.new(repo["full_name"], repo["html_url"] )
      end
    end

    #Apparently Faraday middlewares stablish the connection first appended
    #then "use" the connection to create calls
    def connection
      #this builds the stack
      @connnection ||= Faraday::Connection.new do |builder|
        builder.use Middleware::JasonParser
        builder.use Middleware::Status
        builder.use Middleware::Authentication
        builder.use Middleware::Cache, Storage::Memcached.new # Apparently this is a way to pass in values when initiliazing a part of the stack
        builder.use Middleware::Logging
        builder.adapter Faraday.default_adapter
      end
    end
  end
end
