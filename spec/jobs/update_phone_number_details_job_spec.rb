require 'rails_helper'

RSpec.describe UpdatePhoneNumberDetailsJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform_later' do
    let(:job) { UpdatePhoneNumberDetailsJob.perform_later }

    it 'queues the job' do
      assert_enqueued_jobs 1 do
        job
      end
    end

    it 'queues the job on the exotel_phone_whitelist queue' do
      expect(job.queue_name).to eq('phone_number_details_queue')
    end
  end

  describe '#perform' do
    let!(:patient_phone_number) { create(:patient_phone_number) }
    let(:phone_number) { patient_phone_number.number }
    let(:account_sid) { Faker::Internet.user_name }
    let(:token) { SecureRandom.base64 }
    let(:auth_token) { Base64.strict_encode64([account_sid, token].join(':')) }
    let(:whitelist_details_url) { URI.parse("https://api.exotel.com/v1/Accounts/#{account_sid}/CustomerWhitelist/#{URI.encode(phone_number)}.json") }
    let(:numbers_metadata_url) { URI.parse("https://api.exotel.com/v1/Accounts/#{account_sid}/Numbers/#{URI.encode(phone_number)}.json") }

    let(:request_headers) {
      {
        'Authorization' => "Basic #{auth_token}",
        'Connection' => 'close',
        'Host' => 'api.exotel.com',
        'User-Agent' => 'http.rb/4.1.1'
      }
    }

    let!(:whitelist_details_stub) do
      stub_request(:get, whitelist_details_url).with(headers: request_headers)
        .to_return(
          status: 200,
          headers: {},
          body: JSON(
            { "Result" =>
                { "Status" => "Whitelist",
                  "Type" => "API",
                  "Expiry" => 3600 } }))
    end

    let!(:numbers_metadata_stub) do
      stub_request(:get, numbers_metadata_url).with(headers: request_headers)
        .to_return(
          status: 200,
          headers: {},
          body: JSON(
            { "Numbers" =>
                { "PhoneNumber" => phone_number,
                  "Circle" => "KA",
                  "CircleName" => "Karnataka",
                  "Type" => "Mobile",
                  "Operator" => "V",
                  "OperatorName" => "Vodafone",
                  "DND" => "Yes" } }))
    end

    it 'updates the patient phone number details with the values return from exotel apis' do
      Timecop.freeze do
        UpdatePhoneNumberDetailsJob.perform_now(patient_phone_number.id, account_sid, token)
        expect(patient_phone_number.dnd_status).to eq(true)
        expect(patient_phone_number.phone_type).to eq('mobile')
        expect(patient_phone_number.exotel_phone_number_detail.whitelist_status).to eq('whitelist')
        expect(patient_phone_number.exotel_phone_number_detail.whitelist_status_valid_until).to eq(Time.now + 3600.seconds)
      end
    end
  end
end