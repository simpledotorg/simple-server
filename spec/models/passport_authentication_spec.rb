# frozen_string_literal: true

require "rails_helper"

RSpec.describe PassportAuthentication, type: :model do
  subject(:auth) { PassportAuthentication.new }

  describe "Associations" do
    it { is_expected.to belong_to(:patient_business_identifier) }

    describe "#patient" do
      before { auth.patient_business_identifier = create :patient_business_identifier }

      it "delegates #patient to patient_business_identifier" do
        expect(auth.patient).to eq(auth.patient_business_identifier.patient)
      end
    end
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:access_token) }
    it { is_expected.to validate_presence_of(:otp) }
    it { is_expected.to validate_presence_of(:otp_expires_at) }
    it { is_expected.to validate_presence_of(:patient_business_identifier) }
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
    before { ENV["USER_OTP_VALID_UNTIL_DELTA_IN_MINUTES"] = "5" }

    describe "#generate_otp" do
      it "sets a six digit OTP" do
        auth.otp = nil
        auth.otp_expires_at = nil

        travel_to now do
          auth.generate_otp

          expect(auth.otp).to match(/[0-9]{6}/)
          expect(auth.otp_expires_at).to eq(5.minutes.from_now)
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
        auth.otp_expires_at = nil

        travel_to now do
          auth.reset_otp

          expect(auth.otp).to match(/[0-9]{6}/)
          expect(auth.otp_expires_at).to eq(5.minutes.from_now)
        end
      end

      it "does not generate OTP if already set" do
        auth.otp = "111111"
        auth.reset_otp
        expect(auth.otp).not_to eq("111111")
      end
    end

    describe "#expire_otp" do
      it "expires the OTP" do
        expect(auth).to be_otp_valid
        auth.expire_otp
        expect(auth).not_to be_otp_valid
      end
    end

    describe "#otp_valid?" do
      context "when OTP has not expired" do
        it "returns true" do
          auth.otp_expires_at = 5.minutes.from_now
          expect(auth).to be_otp_valid
        end
      end

      context "when OTP has expired" do
        it "returns false" do
          auth.otp_expires_at = 5.minutes.ago
          expect(auth).not_to be_otp_valid
        end
      end
    end

    describe "#validate_otp" do
      before { allow(auth).to receive(:save!).and_return(true) }

      context "when OTP is valid and correct" do
        let(:otp) { auth.otp }

        it "returns true" do
          expect(auth.validate_otp(otp)).to eq(true)
        end

        it "expires the otp" do
          auth.validate_otp(otp)
          expect(auth).not_to be_otp_valid
        end

        it "generates a new access token" do
          expect { auth.validate_otp(otp) }.to change { auth.access_token }
        end
      end

      context "when OTP is expired" do
        let(:otp) { auth.otp }

        before { auth.otp_expires_at = 5.minutes.ago }

        it "returns false" do
          expect(auth.validate_otp(otp)).to eq(false)
        end
      end

      context "when OTP is incorrect" do
        let(:otp) { "111111" }

        it "returns false" do
          expect(auth.validate_otp(otp)).to eq(false)
        end
      end
    end
  end
end
