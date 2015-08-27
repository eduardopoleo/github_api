require 'faraday'
require 'json'
require 'logger'

module Reports
  class Error < StandardError; end
  class RequestFailure < Error; end
  class NonExistingUser < Error; end

  User = Struct.new(:name, :location, :public_repos)
  VALID_STATUS_CODES = [200, 302, 403, 422, 404]

  class GitHubAPIClient
    def initialize
      @logger = Logger.new(STDOUT)
    end

    def user_info(username)
      url = "https://api.github.com/users/#{username}"
      start_time = Time.now
      response = Faraday.get(url)
      duration = Time.now - start_time

      @logger.debug '-> %s %s %d (%.3f s)' % [url, 'GET', response.status, duration]

      if !VALID_STATUS_CODES.include?(response.status)
        raise RequestFailure, JSON.parse(response.body)["message"]
      end

      if response.status == 404
        raise NonExistingUser, "#{username} not found"
      end

      data = JSON.parse(response.body)
      User.new(data["name"], data["location"], data["public_repos"])
    end
  end
end
