require 'dotenv'
Dotenv.load

require 'reports/github_api_client'
require "time"

module Reports
  RSpec.describe GitHubAPIClient do

    describe "user_info" do
      it "returns the correct user info" do
        user = GitHubAPIClient.new().user_info("eduardopoleo")

        expect(user.name).to eql("Eduardo Poleo")
        expect(user.location).to eql("Toronto, Canada")
        expect(user.public_repos).to eql(50)
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
