require "rspec"

RSpec.describe Messaging::Bsnl::Sms do
  describe "#send_message" do
    it "passes sanitised variable content to the API" do
      mock_api = double("BsnlApiDouble")
      allow(Messaging::Bsnl::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      mock_template = double("BsnlDltTemplate")
      allow(Messaging::Bsnl::DltTemplate).to receive(:new).and_return(mock_template)
      allow(mock_template).to receive(:id).and_return("123")
      allow(mock_template).to receive(:sanitised_variable_content).and_return({"a" => "hash"})
      allow(mock_template).to receive(:check_approved)
      allow(mock_api).to receive(:send_sms).and_return({})

      expect(mock_api).to receive(:send_sms).with(
        recipient_number: "+91123123",
        dlt_template_id: "123",
        key_values: [{"Key" => "a", "Value" => "hash"}]
      )

      described_class.send_message(
        recipient_number: "+91123123",
        dlt_template_name: "notifications.set100.basic",
        variable_content: {}
      )
    end

    it "raises any errors received from BSNL as an exception" do
      mock_api = double("BsnlApiDouble")
      allow(Messaging::Bsnl::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      mock_template = double("BsnlDltTemplate")
      allow(Messaging::Bsnl::DltTemplate).to receive(:new).and_return(mock_template)
      allow(mock_template).to receive(:id).and_return("123")
      allow(mock_template).to receive(:name).and_return("a.template.name")
      allow(mock_template).to receive(:sanitised_variable_content).and_return({"a" => "hash"})
      allow(mock_template).to receive(:check_approved)
      allow(mock_api).to receive(:send_sms).and_return({"Error" => "An error happened."})

      expect {
        described_class.send_message(
          recipient_number: "+91123123",
          dlt_template_name: "notifications.set100.basic",
          variable_content: {}
        )
      }.to raise_error(Messaging::Bsnl::Error, 'An error happened. Error on template a.template.name with content {"a"=>"hash"}')
    end
  end
end
