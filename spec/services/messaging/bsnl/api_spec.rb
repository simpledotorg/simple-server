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
  end

  describe "#get_template_details" do
    it "gets all the templates added to DLT" do
      allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
      allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
      Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")

      stub_request(:post, "https://bulksms.bsnl.in:5010/api/Get_Content_Template_Details").to_return(body: {"Content_Template_Ids" => ["A list of template details"]}.to_json)
      expect(described_class.new.get_template_details).to contain_exactly("A list of template details")
    end
  end

  describe "#name_template_variables" do
    it "names the variables for a DLT template" do
      allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
      allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
      Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")
      template_id = "a template id"
      message_with_named_vars = "message with {#var1#} and {#var2#}"

      request = stub_request(:post, "https://bulksms.bsnl.in:5010/api/Name_Content_Template_Variables").to_return(body: {"Error" => nil, "Template_Keys" => %w[var1 var2]}.to_json)
      expect(described_class.new.name_template_variables(template_id, message_with_named_vars)).to eq("Error" => nil, "Template_Keys" => %w[var1 var2])
      expect(request.with(body: {
        Template_ID: template_id,
        Entity_ID: "123",
        Template_Message_Named: message_with_named_vars
      })).to have_been_mad
  
  describe "#get_message_status_report" do
    it "gets the message's status" do
      allow(ENV).to receive(:[]).with("BSNL_IHCI_HEADER").and_return("ABCDEF")
      allow(ENV).to receive(:[]).with("BSNL_IHCI_ENTITY_ID").and_return("123")
      Configuration.create(name: "bsnl_sms_jwt", value: "a jwt token")

      stub_request(:post, "https://bulksms.bsnl.in:5010/api/Message_Status_Report").to_return(body: {a: :hash}.to_json)
      expect(described_class.new.get_message_status_report(123123)).to eq({"a" => "hash"})
    end
  end
end
