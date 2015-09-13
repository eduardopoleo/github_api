require 'rubygems'
require 'bundler/setup'
require 'thor'
require 'dotenv'
Dotenv.load

require_relative './github_api_client'
require_relative './table_printer'

module Reports
  # - Gets the user input "user_name"
  # - Rescues the Api client error
  # - Outputs the result to the user
  class CLI < Thor
    desc "user_info USERNAME", "Get information for a user"

    def user_info(user_name)
      puts "Getting info for #{user_name}"
      # Using dotenv The enviroment variables are stored in the .env which is
      # hidden in the root directory
      # github tokens for authentication can be generated as shown here
      # https://help.github.com/articles/creating-an-access-token-for-command-line-use/
      client = GitHubAPIClient.new(ENV['GITHUB_TOKEN'])
      user = client.user_info(user_name)

      puts "name: #{user.name}"
      puts "location: #{user.location}"
      puts "public repos: #{user.public_repos}"
    rescue Error => error
      puts "ERROR: #{error.message}"
      exit 1
    end

    desc "repositories USERNAME", "Get public repos for a user"
    def repositories(user_name)
      puts "Getting repos for #{user_name}"

      client = GitHubAPIClient.new(ENV['GITHUB_TOKEN'])
      user_repos = client.repos(user_name)

      user_repos.each do |repo|
        puts "#{repo.name} -  #{repo.url}"
      end

    rescue Error => error
      puts "ERROR: #{error.message}"
      exit 1
    end

    desc "console", "Open an RB session with all dependencies loaded and API defined."
    def console
      require 'irb'
      ARGV.clear
      IRB.start
    end
  end
end
