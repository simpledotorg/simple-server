require "rails_helper"
require "tasks/scripts/clean_bangladesh_phone_numbers"

RSpec.describe CleanBangladeshPhoneNumbers do
  describe ".call" do
    it "removes leading zeros from patient phone numbers" do
      leading_zero_1 = create(:patient_phone_number, number: "01234567890")
      leading_zero_2 = create(:patient_phone_number, number: "09876543210")

      no_leading_zero_1 = create(:patient_phone_number, number: "1212121212")
      no_leading_zero_2 = create(:patient_phone_number, number: "3434343434")

      CleanBangladeshPhoneNumbers.call(verbose: false)

      expect(leading_zero_1.reload.number).to eq("1234567890")
      expect(leading_zero_2.reload.number).to eq("9876543210")

      expect(no_leading_zero_1.reload.number).to eq("1212121212")
      expect(no_leading_zero_2.reload.number).to eq("3434343434")
    end

    it "does nothing in a dryrun" do
      leading_zero_1 = create(:patient_phone_number, number: "01234567890")
      leading_zero_2 = create(:patient_phone_number, number: "09876543210")

      no_leading_zero_1 = create(:patient_phone_number, number: "1212121212")
      no_leading_zero_2 = create(:patient_phone_number, number: "3434343434")

      CleanBangladeshPhoneNumbers.call(verbose: false, dryrun: true)

      expect(leading_zero_1.reload.number).to eq("01234567890")
      expect(leading_zero_2.reload.number).to eq("09876543210")

      expect(no_leading_zero_1.reload.number).to eq("1212121212")
      expect(no_leading_zero_2.reload.number).to eq("3434343434")
    end
  end
end
