require 'faraday'
require 'json'

module Reports
  User = Struct.new(:name, :location, :public_repos)
  class GitHubAPIClient
    def user_info(username)
      response = Faraday.get("https://api.github.com/users/#{username}")
      data = JSON.parse(response.body)
      User.new(data["name"], data["location"], data["public_repos"])
    end
  end
end
