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
      expect(result.error_message).to eq("Your OTP is expired. Request a new one.")
    end
  end

  context "account lockout" do
    it "increments failed attempts" do
      user = FactoryBot.create(:user, password: "5489")
      result = nil
      expect {
        result = PhoneNumberAuthentication::Authenticate.call(otp: user.otp,
          password: "9099",
          phone_number: user.phone_number)
      }.to change { user.phone_number_authentication.failed_attempts }.by(1)
      expect(result).to_not be_success
    end

    it "failed attempts are reset on successful login" do
      user = FactoryBot.create(:user, password: "5489")
      phone_number_authentication = user.phone_number_authentication
      PhoneNumberAuthentication::Authenticate.call(otp: user.otp, password: "bad", phone_number: user.phone_number)
      PhoneNumberAuthentication::Authenticate.call(otp: "xx12", password: "5489", phone_number: user.phone_number)
      expect(phone_number_authentication.reload.failed_attempts).to eq(2)
      result = PhoneNumberAuthentication::Authenticate.call(otp: user.otp, password: "5489", phone_number: user.phone_number)
      expect(result.success?).to be true
      expect(phone_number_authentication.reload.failed_attempts).to eq(0)
    end

    it "increments failed attempts up to five, then sets locked_at time" do
      user = FactoryBot.create(:user, password: "5489")
      phone_number_authentication = user.phone_number_authentication
      PhoneNumberAuthentication::Authenticate.call(otp: user.otp, password: "bad", phone_number: user.phone_number)
      PhoneNumberAuthentication::Authenticate.call(otp: "xx12", password: "5489", phone_number: user.phone_number)
      PhoneNumberAuthentication::Authenticate.call(otp: "xxxx", password: "5489", phone_number: user.phone_number)
      PhoneNumberAuthentication::Authenticate.call(otp: user.otp, password: "bad", phone_number: user.phone_number)
      phone_number_authentication.reload
      expect(phone_number_authentication.failed_attempts).to eq(4)
      expect(phone_number_authentication.locked_at).to be_nil
      time = nil
      Timecop.freeze("January 1 2020 2:00 PM") do
        time = Time.current
        PhoneNumberAuthentication::Authenticate.call(otp: user.otp, password: "bad", phone_number: user.phone_number)
      end
      phone_number_authentication.reload
      expect(phone_number_authentication.failed_attempts).to eq(5)
      expect(phone_number_authentication.locked_at).to eq(time)
    end

    it "returns locked out message if within locked window" do
      user = FactoryBot.create(:user, password: "5489")
      Timecop.freeze("January 1st 2020 12:00") do
        user.phone_number_authentication.update(failed_attempts: 5, locked_at: Time.current)
        Timecop.travel(2.minutes.from_now) do
          result = PhoneNumberAuthentication::Authenticate.call(otp: user.otp, password: "5489", phone_number: user.phone_number)
          expect(result).to_not be_success
          expect(result.error_message).to eq("Your account has been locked for the next 18 minutes. Please wait and try again.")
        end
        Timecop.travel(10.minutes.from_now) do
          result = PhoneNumberAuthentication::Authenticate.call(otp: user.otp, password: "5489", phone_number: user.phone_number)
          expect(result).to_not be_success
          expect(result.error_message).to eq("Your account has been locked for the next 10 minutes. Please wait and try again.")
        end
      end
    end

    it "unlocks the user after 20 minutes" do
      user = FactoryBot.create(:user, password: "5489")
      phone_number_authentication = user.phone_number_authentication
      Timecop.freeze do
        user.phone_number_authentication.update(failed_attempts: 5, locked_at: Time.current)
        Timecop.travel(2.minutes.from_now) do
          result = PhoneNumberAuthentication::Authenticate.call(otp: user.otp, password: "5489", phone_number: user.phone_number)
          expect(result).to_not be_success
          expect(result.error_message).to eq(I18n.t("login.error_messages.account_locked", minutes: 18))
        end
        Timecop.travel(21.minutes.from_now) do
          phone_number_authentication.set_otp # handled by the mobile app I think?
          phone_number_authentication.save
          result = PhoneNumberAuthentication::Authenticate.call(otp: user.otp, password: "5489", phone_number: user.phone_number)
          expect(result).to be_success
          expect(phone_number_authentication.failed_attempts).to eq(0)
          expect(phone_number_authentication.locked_at).to be_nil
        end
      end
    end
  end
end
