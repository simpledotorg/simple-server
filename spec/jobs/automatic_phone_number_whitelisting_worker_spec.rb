require "rails_helper"

RSpec.describe AutomaticPhoneNumberWhitelistingWorker, type: :job do
  let!(:patient) { create(:patient, phone_numbers: []) }
  let!(:phones_numbers_need_whitelisting) { create_list(:patient_phone_number, 5, patient: patient, dnd_status: true) }
  let(:request_body) do
    {
      Language: "en",
      VirtualNumber: virtual_number,
      Number: phones_numbers_need_whitelisting.map(&:number).join(",")
    }
  end
  let(:account_sid) { Faker::Internet.user_name }
  let(:token) { SecureRandom.base64 }
  let(:request_url) { URI.parse("https://api.exotel.com/v1/Accounts/#{account_sid}/CustomerWhitelist.json") }
  let(:virtual_number) { Faker::PhoneNumber.phone_number }
  let!(:auth_token) { Base64.strict_encode64([account_sid, token].join(":")) }
  let!(:request_headers) do
    {
      "Authorization" => "Basic #{auth_token}",
      "Connection" => "close",
      "Host" => "api.exotel.com",
      "Content-Type" => "application/x-www-form-urlencoded",
      "User-Agent" => "http.rb/#{HTTP::VERSION}"
    }
  end
  let!(:stub) do
    stub_request(:post, request_url)
      .with(
        headers: request_headers,
        body: URI.encode_www_form(request_body)
      )
  end

  describe "perform_async" do
    it "queues the job on the low" do
      expect {
        AutomaticPhoneNumberWhitelistingWorker.perform_async(phones_numbers_need_whitelisting.map(&:id), virtual_number, account_sid, token)
      }.to change(Sidekiq::Queues["low"], :size).by(1)
      AutomaticPhoneNumberWhitelistingWorker.drain
    end
  end

  describe "perform" do
    it "calls the exotel whitelist api in batches for all phone numbers that require whitelisting" do
      Flipper.enable(:exotel_whitelist_api)

      AutomaticPhoneNumberWhitelistingWorker.perform_async(phones_numbers_need_whitelisting.map(&:id), virtual_number, account_sid, token)
      AutomaticPhoneNumberWhitelistingWorker.drain
      expect(stub).to have_been_requested

      Flipper.disable(:exotel_whitelist_api)
    end

    it "does not call the exotel whitelist api when feature flag is disabled" do
      AutomaticPhoneNumberWhitelistingWorker.perform_async(phones_numbers_need_whitelisting.map(&:id), virtual_number, account_sid, token)
      AutomaticPhoneNumberWhitelistingWorker.drain
      expect(stub).not_to have_been_requested
    end

    it "updates the whitelist_requested_at for all the patient phone numbers" do
      Timecop.freeze do
        AutomaticPhoneNumberWhitelistingWorker.perform_async(phones_numbers_need_whitelisting.map(&:id), virtual_number, account_sid, token)
        AutomaticPhoneNumberWhitelistingWorker.drain
        phones_numbers_need_whitelisting.each do |phone_number|
          expect(phone_number.exotel_phone_number_detail.whitelist_requested_at.to_i).to eq(Time.current.to_i)
        end
      end
    end
  end
end
