require 'faraday'
require 'json'
require 'logger'
require_relative 'middleware/logging'

module Reports
  class Error < StandardError; end
  class RequestFailure < Error; end
  class NonExistingUser < Error; end
  class AuthenticationFailure < Error; end

  User = Struct.new(:name, :location, :public_repos)
  Repo = Struct.new(:name, :url)
  VALID_STATUS_CODES = [200, 302, 403, 422, 404, 401]

  #Concerns of the client:
  #This could probably be seen as on big concern: Handling Api call.
    # - Set the headers of the response, (this is where the token goes)
    # - Makes the api call, including the auth token
    # - Check and raise response errors
    # - Parse user information
    # - Creates and returns user
  class GitHubAPIClient
    def initialize(token)
      @token = token
    end

    def user_info(username)
      headers = {"Authorization" => "token #{@token}"}
      url = "https://api.github.com/users/#{username}"

      response = connection.get(url, nil, headers)

      if !VALID_STATUS_CODES.include?(response.status)
        raise RequestFailure, JSON.parse(response.body)["message"]
      end

      if response.status == 401
        raise AuthenticationFailure, "Authentication Failed please send the correct github token"
      end

      if response.status == 404
        raise NonExistingUser, "#{username} not found"
      end

      data = JSON.parse(response.body)
      User.new(data["name"], data["location"], data["public_repos"])
    end

    def repos(username)
      headers = {"Authorization" => "token #{@token}"}
      url = "https://api.github.com/users/#{username}/repos"

      response = connection.get(url, nil, headers)

      if !VALID_STATUS_CODES.include?(response.status)
        raise RequestFailure, JSON.parse(response.body)["message"]
      end

      if response.status == 401
        raise AuthenticationFailure, "Authentication Failed please send the correct github token"
      end

      if response.status == 404
        raise NonExistingUser, "#{username} not found"
      end

      raw_data = JSON.parse(response.body)
      repos = raw_data.map do |raw_repo|
        Repo.new(raw_repo["full_name"], raw_repo["html_url"] )
      end
    end

    #Apparently Faraday middlewares stablish the connection first appended
    #then "use" the connection to create calls
    def connection
      #this build the stack
      @connnection ||= Faraday::Connection.new do |builder|
        builder.use Middleware::Logging
        builder.adapter Faraday.default_adapter
      end
    end
  end
end
