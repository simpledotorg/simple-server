require "rails_helper"

RSpec.describe Messaging::Bsnl::Api do
  it "raises an error if configuration is missing" do
    stub_request(:post, "https://bulksms.bsnl.in:5010/api/Get_Content_Template_Details").to_return(body: {"Content_Template_Ids" => ["A list of template details"]}.to_json)
    expect { described_class.new.get_template_details }.to raise_error(Messaging::Bsnl::Error)
  end

  it "gets all the templates added to DLT" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
    allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
    Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")

    stub_request(:post, "https://bulksms.bsnl.in:5010/api/Get_Content_Template_Details").to_return(body: {"Content_Template_Ids" => ["A list of template details"]}.to_json)
    expect(described_class.new.get_template_details).to contain_exactly("A list of template details")
  end
end
