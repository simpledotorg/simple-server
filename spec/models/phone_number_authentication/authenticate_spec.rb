require "rails_helper"

RSpec.describe PhoneNumberAuthentication::Authenticate do
  context "successful auth" do
    it "returns success" do
      user = FactoryBot.create(:user, password: "5489")
      result = PhoneNumberAuthentication::Authenticate.call(otp: user.otp,
        password: "5489",
        phone_number: user.phone_number)
      expect(result).to be_success
      expect(result.error_message).to be_nil
    end

    it "generates access token" do
      user = FactoryBot.create(:user, password: "5489")
      expect {
        PhoneNumberAuthentication::Authenticate.call(otp: user.otp,
          password: "5489",
          phone_number: user.phone_number)
      }.to change { user.phone_number_authentication.access_token }
    end

    it "invalidates OTP" do
      user = FactoryBot.create(:user, password: "5489")
      expect(user.otp_valid?).to be true
      PhoneNumberAuthentication::Authenticate.call(otp: user.otp,
        password: "5489",
        phone_number: user.phone_number)
      expect(user.phone_number_authentication.otp_expires_at).to eq(Time.at(0))
      expect(user.otp_valid?).to be false
    end
  end

  context "fails when" do
    it "phone number is not found" do
      result = PhoneNumberAuthentication::Authenticate.call(otp: "1234",
        password: "5489",
        phone_number: "2487531510")
      expect(result).to_not be_success
      expect(result.error_message).to eq("We don't recognize that user. Please check and try again.")
    end

    it "password does not match" do
      user = FactoryBot.create(:user, password: "5489")
      result = PhoneNumberAuthentication::Authenticate.call(otp: user.otp,
        password: "9099",
        phone_number: user.phone_number)
      expect(result).to_not be_success
      expect(result.error_message).to eq("Your password does not match. Try again?")
    end

    it "otp does not match" do
      user = FactoryBot.create(:user, password: "5489")
      result = PhoneNumberAuthentication::Authenticate.call(otp: "1234",
        password: "5489",
        phone_number: user.phone_number)
      expect(result).to_not be_success
      expect(result.error_message).to eq("Your OTP does not match. Try again?")
    end

    it "otp is expired" do
      user = Timecop.freeze(Date.current - 3) { FactoryBot.create(:user, password: "5489") }
      result = PhoneNumberAuthentication::Authenticate.call(otp: user.otp,
        password: "5489",
        phone_number: user.phone_number)
      expect(result).to_not be_success
      expect(result.error_message).to eq("You need a fresh OTP. Request a new one.")
    end
  end
end