require 'faraday'
require 'json'
require 'logger'

module Reports
  class NonExistentUser < StandardError; end
  
  User = Struct.new(:name, :location, :public_repos)
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
      if response.status == 404
        raise NonExistentUser, "#{username} does not exist"
      end

      data = JSON.parse(response.body)
      User.new(data["name"], data["location"], data["public_repos"])
    end
  end
end
