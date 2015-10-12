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

    rescue Error => error
      puts "ERROR: #{error.message}"
      exit 1
    end

    desc "repositories USERNAME", "Get public repos for a user"
    def repositories(user_name, fork=false)
      puts "Getting repos for #{user_name}"

      client = GitHubAPIClient.new()
      user_repos = client.repos(user_name, fork)

      puts
      puts

      table_printer = TablePrinter.new(STDOUT)


      user_repos.each do |repo|
        table_printer.print(repo["languages"], title: "Language breakdown for #{repo.name}", humanize: true)
      end

    rescue Error => error
      puts "ERROR: #{error.message}"
      exit 1
    end

    desc "star_repo FULL_REPO_NAME", "Star a repository"
    def star_repo(repo_name)
      puts "Starring #{repo_name}..."
      client = GitHubAPIClient.new

      if client.repo_starred?(repo_name)
        puts "you have already starred #{repo_name}"
      else
        client.star_repo(repo_name)
        puts "You have astarred #{repo_name}"
      end
    rescue Error => error
      puts "ERROR #{error.message}"
      exit 1
    end

    desc "unstar_repo FULL_REPO_NAME", "Unstar a repository"
    def unstar_repo(repo_name)
      puts "Unstarring #{repo_name}..."

      client = GitHubAPIClient.new

      if client.repo_starred?(repo_name)
        client.unstar_repo(repo_name)
        puts "You have unstarred #{repo_name}."
      else
        puts "You have not starred #{repo_name}."
      end
    rescue Error => error
      puts "ERROR #{error.message}"
      exit 1
    end

    desc "console", "Open an RB session with all dependencies loaded and API defined."
    def console
      require 'irb'
      ARGV.clear
      IRB.start
    end

    desc "gist DESCRIPTION FILENAME CONTENTS", "Create a private Gist on GitHub"
    desc "activity", "Create a new private gist"
    def gist(description, file, content)
      puts "Creating a new private gist..."

      client = GitHubAPIClient.new
      gist = client.create_private_gist(description, file, content)
      puts "You just created a new gist at #{gist}"
    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1
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
