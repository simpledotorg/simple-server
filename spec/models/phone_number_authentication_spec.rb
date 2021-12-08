require "rails_helper"

RSpec.describe PhoneNumberAuthentication, type: :model do
  describe "Associations" do
    it { should have_one(:user_authentication) }
    it { should have_one(:user).through(:user_authentication) }
    it { should belong_to(:facility).with_foreign_key("registration_facility_id") }
  end

  describe "Validations" do
    let(:user) { create(:user) }
    let(:registration_facility) { create(:facility) }
    let(:subject) { user.phone_number_authentication }

    it { should validate_presence_of(:phone_number) }
    it { should validate_uniqueness_of(:phone_number).ignoring_case_sensitivity }

    context "presence of password" do
      it "validates with a password" do
        auth = build(:phone_number_authentication, password: "1234")
        expect(auth).to be_valid
      end

      it "validates with a password_digest" do
        auth = build(:phone_number_authentication, :with_password_digest)
        expect(auth).to be_valid
      end

      it "invalidates without a password or a password_digest" do
        auth = build(:phone_number_authentication, password: nil, password_digest: nil)
        expect(auth).to be_invalid
        expect(auth.errors[:password]).to match_array(["can't be blank", "Either password_digest or password should be present"])
      end

      it "invalidates with more than USER_AUTH_MAX_FAILED_ATTEMPTS failed_attempts" do
        attempts = PhoneNumberAuthentication::USER_AUTH_MAX_FAILED_ATTEMPTS + 1
        auth = build(:phone_number_authentication, failed_attempts: attempts)
        expect(auth).to be_invalid
        expect(auth.errors[:failed_attempts]).to eq(["must be less than or equal to 5"])
      end
    end
  end

  describe "lockouts" do
    it "is in lockout period if lockout time is in past" do
      auth = build(:phone_number_authentication, locked_at: 10.minutes.ago)
      expect(auth).to be_in_lockout_period
    end

    it "clears lockout tracking if unlocked" do
      auth = create(:phone_number_authentication, locked_at: 10.minutes.ago, failed_attempts: 5)
      expect(auth).to be_in_lockout_period
      auth.unlock
      expect(auth).to_not be_in_lockout_period
    end

    it "can calculate minutes left in lockout" do
      Timecop.freeze do
        auth = build(:phone_number_authentication, locked_at: 15.minutes.ago, failed_attempts: 5)
        expect(auth).to be_in_lockout_period
        expect(auth.minutes_left_on_lockout).to eq(5)
      end
    end

    it "can calculate seconds left in lockout" do
      Timecop.freeze do
        auth = build(:phone_number_authentication, locked_at: 19.minutes.ago, failed_attempts: 5)
        expect(auth).to be_in_lockout_period
        expect(auth.seconds_left_on_lockout).to eq(60)
      end
    end
  end

  describe "invalidate_otp" do
    subject(:authentication) { described_class.new(otp: "123456", otp_expires_at: Time.now) }

    it "clears the otp fields" do
      authentication.invalidate_otp
      expect(authentication.otp_expires_at.to_i).to eq(0)
    end
  end

  describe "localized_phone_number" do
    it_behaves_like "phone_number_localizable"
  end
end
