require 'dotenv'
Dotenv.load

require 'reports/github_api_client'
require "time"
require 'remote_helper'

module Reports
  RSpec.describe GitHubAPIClient, remote: true do

    describe "user_info" do
      it "returns the correct user info" do
        user = GitHubAPIClient.new().user_info("eduardopoleo")

        expect(user.name).to be_instance_of(String)
        expect(user.location).to be_instance_of(String)
        expect(user.public_repos).to be_instance_of(Fixnum)
      end

      it "raises an exception if the user does not exist" do
        client = GitHubAPIClient.new()

        expect(->{
          client.user_info("flkjaslkfasklfjasklfjas")
        }).to raise_error(NonExistingUser)
      end
    end
  end
end
