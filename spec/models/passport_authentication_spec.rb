require 'rails_helper'

RSpec.describe PassportAuthentication, type: :model do
  subject(:auth) { PassportAuthentication.new }

  describe 'Associations' do
    it { should belong_to(:patient) }
    it { should belong_to(:patient_business_identifier) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:access_token) }
    it { should validate_presence_of(:otp) }
    it { should validate_presence_of(:otp_valid_until) }
    it { should validate_presence_of(:patient) }
    it { should validate_presence_of(:patient_business_identifier) }
  end

  describe "Access Token" do
    describe "#generate_access_token" do
      it "sets a 32-digit hex token" do
        auth.access_token = nil
        auth.generate_access_token
        expect(auth.access_token).to match(/[a-z0-9]{32}/)
      end

      it "does not generate if already set" do
        auth.access_token = "test token"
        auth.generate_access_token
        expect(auth.access_token).to eq("test token")
      end
    end

    describe "#reset_access_token" do
      it "sets a 32-digit hex token" do
        auth.access_token = nil
        auth.reset_access_token
        expect(auth.access_token).to match(/[a-z0-9]{32}/)
      end

      it "generates a new access token if already set" do
        auth.access_token = "test token"
        auth.reset_access_token
        expect(auth.access_token).not_to eq("test token")
      end
    end
  end

  describe "OTP" do
    include ActiveSupport::Testing::TimeHelpers
    let(:now) { Time.current }
    before { ENV['USER_OTP_VALID_UNTIL_DELTA_IN_MINUTES'] = '5' }

    describe "#generate_otp" do
      it "sets a six digit OTP" do
        auth.otp = nil
        auth.otp_valid_until = nil

        travel_to now do
          auth.generate_otp

          expect(auth.otp).to match(/[0-9]{6}/)
          expect(auth.otp_valid_until).to eq(5.minutes.from_now)
        end
      end

      it "does not generate OTP if already set" do
        auth.otp = "111111"
        auth.generate_otp
        expect(auth.otp).to eq("111111")
      end
    end

    describe "#reset_otp" do
      it "sets a six digit OTP" do
        auth.otp = nil
        auth.otp_valid_until = nil

        travel_to now do
          auth.reset_otp

          expect(auth.otp).to match(/[0-9]{6}/)
          expect(auth.otp_valid_until).to eq(5.minutes.from_now)
        end
      end

      it "does not generate OTP if already set" do
        auth.otp = "111111"
        auth.reset_otp
        expect(auth.otp).not_to eq("111111")
      end
    end
  end
end
