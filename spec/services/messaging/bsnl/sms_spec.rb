require "rails_helper"

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

  describe ".get_message_statuses" do
    it "picks up any in progress BSNL delivery details and queues a BsnlSmsStatusJob" do
      create_list(:bsnl_delivery_detail, 2, :created)

      expect { described_class.get_message_statuses }.to change(Sidekiq::Queues["default"], :size).by(2)
    end

    it "only includes messages sent in the last 2 days" do
      # BSNL only keeps delivery receipts for 2 days
      create(:bsnl_delivery_detail, :created, created_at: 3.days.ago)
      create(:bsnl_delivery_detail, :created, created_at: 1.days.ago)

      expect { described_class.get_message_statuses }.to change(Sidekiq::Queues["default"], :size).by(1)
    end
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
      }.to raise_error(an_instance_of(Messaging::Bsnl::Error)) do |error|
        expect(error.reason).to be_nil
        expect(/An error happened. Error sending SMS for a.template.name/).to match(error.message)
      end
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
