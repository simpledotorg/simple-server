require "rspec"

RSpec.describe Messaging::Bsnl::Sms do
  def mock_template
    mock_template = double("BsnlDltTemplate")
    allow(Messaging::Bsnl::DltTemplate).to receive(:new).and_return(mock_template)
    allow(mock_template).to receive(:id).and_return("123")
    allow(mock_template).to receive(:name).and_return("a.template.name")
    allow(mock_template).to receive(:sanitised_variable_content).and_return([{"Key" => "a", "Value" => "hash"}])
    allow(mock_template).to receive(:check_approved)
    mock_template
  end

  describe "#send_message" do
    it "passes sanitised variable content to the API" do
      template = mock_template
      mock_api = double("BsnlApiDouble")
      allow(Messaging::Bsnl::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      allow(mock_api).to receive(:send_sms).and_return({"Message_Id" => "1111111"})

      expect(mock_api).to receive(:send_sms).with(
        recipient_number: "+91123123",
        dlt_template: template,
        key_values: [{"Key" => "a", "Value" => "hash"}]
      )

      described_class.send_message(
        recipient_number: "+91123123",
        dlt_template_name: template.name,
        variable_content: {}
      )
    end

    it "raises any errors received from BSNL as an exception" do
      template = mock_template
      mock_api = double("BsnlApiDouble")
      allow(Messaging::Bsnl::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      allow(mock_api).to receive(:send_sms).and_return({"Error" => "An error happened."})

      expect {
        described_class.send_message(
          recipient_number: "+91123123",
          dlt_template_name: template.name,
          variable_content: {}
        )
      }.to raise_error(Messaging::Bsnl::Error, 'An error happened. Error on template a.template.name with content [{"Key"=>"a", "Value"=>"hash"}]')
    end

    it "creates a detailable and a communication and returns it" do
      recipient_phone_number = "+918585858585"
      template = mock_template
      mock_api = double("BsnlApiDouble")
      allow(Messaging::Bsnl::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      mock_message_id = "123456"
      allow(mock_api).to receive(:send_sms).and_return({"Message_Id" => mock_message_id})

      communication = described_class.send_message(
        recipient_number: recipient_phone_number,
        dlt_template_name: template.name,
        variable_content: {a: :hash}
      )
      expect(communication.detailable.recipient_number).to eq recipient_phone_number
      expect(communication.detailable.message_id).to eq mock_message_id
    end

    it "calls the block passed to it with the communication created" do
      mock_api = double("BsnlApiDouble")
      allow(Messaging::Bsnl::Api).to receive(:new).and_return(mock_api)
      allow(mock_api).to receive(:send_sms)
      mock_message_id = "123456"
      allow(mock_api).to receive(:send_sms).and_return({"Message_Id" => mock_message_id})
      spy = spy("Awaits a_method to be called")

      described_class.send_message(recipient_number: "+918585858585", dlt_template_name: mock_template, variable_content: {}) { |_|
        spy.a_method
      }
      expect(spy).to have_received(:a_method)
    end
  end
end
