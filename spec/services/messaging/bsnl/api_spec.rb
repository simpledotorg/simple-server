require "rails_helper"

RSpec.describe Messaging::Bsnl::Api do
  it "raises an error if configuration is missing" do
    stub_request(:post, "https://bulksms.bsnl.in:5010/api/Get_Content_Template_Details").to_return(body: {"Content_Template_Ids" => ["A list of template details"]}.to_json)

    expect { described_class.new }.to raise_error(Messaging::Bsnl::Error)
  end

  describe "#send_sms" do
    it "strips +91 from recipient_number because BSNL expects 10 digit mobile numbers" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
      allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
      Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")
      mock_template = double("DltTemplate")
      allow(mock_template).to receive(:is_unicode).and_return "1"
      allow(mock_template).to receive(:id).and_return "1234"

      request = stub_request(:post, "https://bulksms.bsnl.in:5010/api/Send_Sms")
      described_class.new.send_sms(recipient_number: "+911111111111", dlt_template: mock_template, key_values: {})
      expect(request.with(body: {
        "Header" => "ABCDEF",
        "Target" => "1111111111",
        "Is_Unicode" => "1",
        "Is_Flash" => "0",
        "Message_Type" => "SI",
        "Entity_Id" => "123",
        "Content_Template_Id" => "1234",
        "Template_Keys_and_Values" => {}
      })).to have_been_made
    end

    it "falls back to picking up JWT token from ENV for testing purposes" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
      allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
      allow(ENV).to receive(:[]).with("BSNL_JWT_TOKEN").and_return("ey123123")

      expect(Configuration.fetch("bsnl_sms_jwt")).to be_nil
      expect { described_class.new }.not_to raise_error(Messaging::Bsnl::Error)
    end
  end

  describe "#get_template_details" do
    it "gets all the templates added to DLT" do
      allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
      allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
      allow(ENV).to receive(:[]).with("BSNL_JWT_TOKEN").and_return("ey123123")

      stub_request(:post, "https://bulksms.bsnl.in:5010/api/Get_Content_Template_Details").to_return(body: {"Content_Template_Ids" => ["A list of template details"]}.to_json)
      expect(described_class.new.get_template_details).to contain_exactly("A list of template details")
    end
  end
end
