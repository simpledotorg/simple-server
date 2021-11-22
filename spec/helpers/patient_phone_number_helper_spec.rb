require "rails_helper"

RSpec.describe PatientPhoneNumberHelper, type: :helper do
  describe "#number_with_country_code" do
    it "adds the country code when one is not present" do
      phone_number = "1234567890"
      expect(helper.number_with_country_code(phone_number)).to eq("+911234567890")
    end

    it "does not change the number if it's already localized correctly" do
      phone_number = "+911234567890"
      expect(helper.number_with_country_code(phone_number)).to eq("+911234567890")
    end

    it "adds a plus sign when missing" do
      phone_number = "911234567890"
      expect(helper.number_with_country_code(phone_number)).to eq("+911234567890")
    end

    it "changes the number to the current country code if it is localized to another country" do
      phone_number = "+11234567890"
      expect(helper.number_with_country_code(phone_number)).to eq("+911234567890")
    end

    it "ignores non-alphanumeric characters" do
      phone_number = "123-456-7890"
      expect(helper.number_with_country_code(phone_number)).to eq("+911234567890")
    end

    it "treats short numbers as complete" do
      phone_number = "1"
      expect(helper.number_with_country_code(phone_number)).to eq("+911")
    end

    it "treats long numbers as valid" do
      phone_number = "1234567890987654321"
      expect(helper.number_with_country_code(phone_number)).to eq("+911234567890987654321")
    end

    context "with different country configs" do
      after :each do
        Rails.application.config.country[:abbreviation] = "IN"
        Rails.application.config.country[:sms_country_code] = "+91"
      end

      it "strips leading characters according to country abbreviation" do
        Rails.application.config.country[:abbreviation] = "US"

        phone_number = "1234567890"
        expect(helper.number_with_country_code(phone_number)).to eq("+91234567890")
      end

      it "adds country code according to sms_country_code" do
        Rails.application.config.country[:sms_country_code] = "+1"

        phone_number = "+911234567890"
        expect(helper.number_with_country_code(phone_number)).to eq("+11234567890")
      end
    end
  end
end
