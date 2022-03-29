require "rails_helper"
require "tasks/scripts/bsnl"

RSpec.describe Bsnl do
  describe "#refresh_sms_jwt" do
    context "BSNL credentials are not available" do
      it "doesn't try to refresh the JWT" do
        Configuration.create(name: "bsnl_sms_jwt", value: "old_jwt")
        request = stub_request(:post, "https://bulksms.bsnl.in:5010/api/Create_New_API_Token").to_return(body: "\"new_jwt\"")

        expect { described_class.new(nil, "username", "password", "X").refresh_sms_jwt }.to raise_error(SystemExit)
        expect(request).not_to have_been_made
        expect(Configuration.fetch("bsnl_sms_jwt")).to eq("old_jwt")
      end
    end

    context "BSNL credentials are available" do
      it "tries to refresh the JWT" do
        Configuration.create(name: "bsnl_sms_jwt", value: "old_jwt")
        request = stub_request(:post, "https://bulksms.bsnl.in:5010/api/Create_New_API_Token").to_return(body: "\"new_jwt\"")

        expect { described_class.new("1", "username", "password", "X").refresh_sms_jwt }.not_to raise_error
        expect(request).to have_been_made
        expect(Configuration.fetch("bsnl_sms_jwt")).to eq("new_jwt")
      end
    end
  end
end
