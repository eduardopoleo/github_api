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
    desc "activity USERNAME", "Gets info about events for an specific user"
    def activity(user_name)
      puts "Fetching activity summary for #{user_name}"

      client = GitHubAPIClient.new()
      event_activities = client.activity(user_name)

      print_activity_report(event_activities)
    rescue Error => error
      puts "ERROR #{error.message}"
      exit 1
    end

    desc "user_info USERNAME", "Get information for a user"
    def user_info(user_name)
      puts "Getting info for #{user_name}"
      # Using dotenv The enviroment variables are stored in the .env which is
      # hidden in the root directory
      # github tokens for authentication can be generated as shown here
      # https://help.github.com/articles/creating-an-access-token-for-command-line-use/
      client = GitHubAPIClient.new()
      user = client.user_info(user_name)

      puts "name: #{user.name}"
      puts "location: #{user.location}"
      puts "public repos: #{user.public_repos}"

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

      client = GitHubAPIClient.new()
      user_repos = client.repos(user_name)

      puts
      puts 
      user_repos.each do |repo|
        puts "#{repo.name} -  #{repo.url}"
      end
        puts
        puts
      user_repos.each do |repo|
        puts "#{repo.name}: #{repo.languages.join(',')}"
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
    private

    def print_activity_report(events)
      table_printer = TablePrinter.new(STDOUT)
      event_types_map = events.each_with_object(Hash.new(0)) do |event, counts|
        counts[event.type] += 1
      end
      #{pushevents: 2, commitevents: 5, commentevent: 9} etc, and this is require cus?
      table_printer.print(event_types_map, title: "Event Summary", total: true)

      push_events_map = events.each_with_object(Hash.new(0)) do |event, counts|
        counts[event.repo] += 1
      end
      puts
      table_printer.print(push_events_map, title: "Project Push Sumary", total: true)
    end
  end
end
