require 'rubygems'
require 'bundler/setup'
require 'thor'

require_relative './github_api_client'
require_relative './table_printer'

module Reports

  class CLI < Thor
    desc "user_info USERNAME", "Get information for a user"
    def self.user_info(user_name)
      puts "Getting info for #{user_name}"

      client = GitHubAPIClient.new
      user = client.user_info(user_name)
      puts "name: #{user.name}"
      puts "location: #{user.location}"
      puts "public repos: #{user.public_repos}"
    end

    desc "console", "Open an RB session with all dependencies loaded and API defined."
    def console
      require 'irb'
      ARGV.clear
      IRB.start
    end

    private

    def client
      @client ||= GitHubAPIClient.new
    end

  end

end
