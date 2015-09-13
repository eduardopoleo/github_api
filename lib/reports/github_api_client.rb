require 'faraday'
require 'json'
require 'logger'

module Reports
  class Error < StandardError; end
  class RequestFailure < Error; end
  class NonExistingUser < Error; end
  class AuthenticationFailure < Error; end

  User = Struct.new(:name, :location, :public_repos)
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
      @logger = Logger.new(STDOUT)
    end

    def user_info(username)
      headers = {"Authorization" => "token #{@token}"}
      url = "https://api.github.com/users/#{username}"

      start_time = Time.now
      response = Faraday.get(url, nil, headers)
      duration = Time.now - start_time

      @logger.debug '-> %s %s %d (%.3f s)' % [url, 'GET', response.status, duration]

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
  end
end
