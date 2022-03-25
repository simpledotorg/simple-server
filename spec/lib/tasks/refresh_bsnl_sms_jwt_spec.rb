require "rails_helper"
require "rake"

Rails.application.load_tasks

RSpec.describe "RefreshBsnlSmsJwt" do
  after do
    Rake::Task["bsnl:refresh_sms_jwt"].reenable
  end

  context "BSNL credentials are not available" do
    it "doesn't try to refresh the JWT" do
      Configuration.create(name: "bsnl_sms_jwt", value: "old_jwt")
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("BSNL_SERVICE_ID").and_return(nil)
      allow(ENV).to receive(:[]).with("BSNL_USERNAME").and_return("username")
      allow(ENV).to receive(:[]).with("BSNL_PASSWORD").and_return("password")
      allow(ENV).to receive(:[]).with("BSNL_TOKEN_ID").and_return("X")

      request = stub_request(:post, "https://bulksms.bsnl.in:5010/api/Create_New_API_Token").to_return(body: "\"new_jwt\"")
      expect { Rake::Task["bsnl:refresh_sms_jwt"].invoke }.to raise_error(SystemExit)

      expect(request).not_to have_been_made
      expect(Configuration.fetch("bsnl_sms_jwt")).to eq("old_jwt")
    end
  end

  context "BSNL credentials are available" do
    it "tries to refresh the JWT" do
      Configuration.create(name: "bsnl_sms_jwt", value: "old_jwt")
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("BSNL_SERVICE_ID").and_return("1")
      allow(ENV).to receive(:[]).with("BSNL_USERNAME").and_return("username")
      allow(ENV).to receive(:[]).with("BSNL_PASSWORD").and_return("password")
      allow(ENV).to receive(:[]).with("BSNL_TOKEN_ID").and_return("X")

      request = stub_request(:post, "https://bulksms.bsnl.in:5010/api/Create_New_API_Token").to_return(body: "\"new_jwt\"")
      Rake::Task["bsnl:refresh_sms_jwt"].invoke

      expect(request).to have_been_made
      expect(Configuration.fetch("bsnl_sms_jwt")).to eq("new_jwt")
    end
  end
end
