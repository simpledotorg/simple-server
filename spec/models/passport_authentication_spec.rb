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

  describe "Authentication" do
    describe "#generate_access_token" do
      it "returns a 32-digit hex token" do
        expect(auth.generate_access_token).to match(/[a-z0-9]{32}/)
      end

      it "does not generate if already set" do
        auth.access_token = "test token"
        expect(auth.generate_access_token).to eq("test token")
      end
    end

    describe "#generate_otp" do
      it "returns a six digit OTP" do
        expect(auth.generate_otp[:otp]).to match(/[0-9]{6}/)
      end

      it "does not generate OTP if already set" do
        auth.otp = "111111"
        expect(auth.generate_otp[:otp]).to eq("111111")
      end
    end
  end
end
