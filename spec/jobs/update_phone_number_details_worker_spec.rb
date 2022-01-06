# frozen_string_literal: true

require "rails_helper"

RSpec.describe UpdatePhoneNumberDetailsWorker, type: :job do
  include ActiveJob::TestHelper

  let(:patient_phone_number) { create(:patient_phone_number, phone_type: "landline") }
  let(:phone_number) { patient_phone_number.number }
  let(:account_sid) { Faker::Internet.user_name }
  let(:token) { SecureRandom.base64 }
  let(:auth_token) { Base64.strict_encode64([account_sid, token].join(":")) }
  let(:whitelist_details_url) { URI.parse("https://api.exotel.com/v1/Accounts/#{account_sid}/CustomerWhitelist/#{CGI.escape(phone_number)}.json") }
  let(:numbers_metadata_url) { URI.parse("https://api.exotel.com/v1/Accounts/#{account_sid}/Numbers/#{CGI.escape(phone_number)}.json") }

  let(:request_headers) do
    {
      "Authorization" => "Basic #{auth_token}",
      "Connection" => "close",
      "Host" => "api.exotel.com",
      "User-Agent" => "http.rb/#{HTTP::VERSION}"
    }
  end

  let!(:whitelist_details_stub) do
    stub_request(:get, whitelist_details_url).with(headers: request_headers)
      .to_return(
        status: 200,
        headers: {},
        body: JSON(
          "Result" =>
             {"Status" => "Whitelist",
              "Type" => "API",
              "Expiry" => 3600}
        )
      )
  end

  let!(:numbers_metadata_stub) do
    stub_request(:get, numbers_metadata_url).with(headers: request_headers)
      .to_return(
        status: 200,
        headers: {},
        body: JSON(
          "Numbers" =>
             {"PhoneNumber" => phone_number,
              "Circle" => "KA",
              "CircleName" => "Karnataka",
              "Type" => "Mobile",
              "Operator" => "V",
              "OperatorName" => "Vodafone",
              "DND" => "Yes"}
        )
      )
  end

  describe "#perform_async" do
    it "queues the job on the low queue" do
      expect {
        UpdatePhoneNumberDetailsWorker.perform_async(patient_phone_number.id, account_sid, token)
      }.to change(Sidekiq::Queues["low"], :size).by(1)
      UpdatePhoneNumberDetailsWorker.clear
    end
  end

  describe "#perform" do
    it "skips the update if the phone number is missing a patient" do
      patient_phone_number.patient.discard!
      UpdatePhoneNumberDetailsWorker.perform_async(patient_phone_number.id, account_sid, token)
      expect { UpdatePhoneNumberDetailsWorker.drain }.to not_change { patient_phone_number }
    end

    it "updates the patient phone number details with the values return from exotel apis" do
      UpdatePhoneNumberDetailsWorker.perform_async(patient_phone_number.id, account_sid, token)
      time = Time.current
      Timecop.freeze(time) do
        UpdatePhoneNumberDetailsWorker.drain
      end
      patient_phone_number.reload
      expect(patient_phone_number.dnd_status).to eq(true)
      expect(patient_phone_number.phone_type).to eq("mobile")
      expect(patient_phone_number.exotel_phone_number_detail.whitelist_status).to eq("whitelist")
      expect(patient_phone_number.exotel_phone_number_detail.whitelist_status_valid_until.to_i).to eq((time + 3600.seconds).to_i)
    end
  end
end
