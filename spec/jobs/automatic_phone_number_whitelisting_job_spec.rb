require 'rails_helper'

RSpec.describe AutomaticPhoneNumberWhitelistingJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform_later' do
    let(:job) { AutomaticPhoneNumberWhitelistingJob.perform_later }

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
    let!(:patient) { create(:patient, phone_numbers: []) }
    let!(:phones_numbers_need_whitelisting) { create_list(:patient_phone_number, 5, patient: patient, dnd_status: true) }
    let(:batch_size) { 2 }
    let(:phone_number_batches) { phones_numbers_need_whitelisting.each_slice(batch_size) }
    let(:request_bodies) do
      phone_number_batches.map do |phone_numbers|
        {
          :Language => 'en',
          :VirtualNumber => virtual_number,
          :Number => phone_numbers.map(&:number).join(',')
        }
      end
    end
    let(:account_sid) { Faker::Internet.user_name }
    let(:token) { SecureRandom.base64 }
    let(:request_url) { URI.parse("https://api.exotel.com/v1/Accounts/#{account_sid}/CustomerWhitelist.json") }
    let(:virtual_number) { Faker::PhoneNumber.phone_number }
    let!(:auth_token) { Base64.strict_encode64([account_sid, token].join(':')) }
    let!(:request_headers) {
      {
        'Authorization' => "Basic #{auth_token}",
        'Connection' => 'close',
        'Host' => 'api.exotel.com',
        'Content-Type'=>'application/x-www-form-urlencoded',
        'User-Agent' => 'http.rb/4.1.1'
      }
    }
    let!(:stubs) do
      request_bodies.map do |request_body|
        stub_request(:post, request_url)
          .with(
          headers: request_headers,
          body: request_body)
      end
    end

    it "calls the exotel whitelist api in batches for all phone numbers that require whitelisting" do
      AutomaticPhoneNumberWhitelistingJob.perform_now(virtual_number, account_sid, token, batch_size: 2)
      expect(stubs.first).to  have_been_requested
      expect(stubs.second).to have_been_requested
      expect(stubs.third).to  have_been_requested
    end

    it "updates the whitelist_requested_at for all the patient phone numbers" do
      Timecop.freeze do
        AutomaticPhoneNumberWhitelistingJob.perform_now(virtual_number, account_sid, token, batch_size)
        phones_numbers_need_whitelisting.each do |phone_number|
          expect(phone_number.exotel_phone_number_detail.whitelist_requested_at).to eq(Time.now)
        end
      end
    end
  end
end