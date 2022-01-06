# frozen_string_literal: true

require "rails_helper"

describe MarkPatientMobileNumbers, type: :model do
  it "marks non-mobile patient phone numbers as mobile" do
    mobile_number = create(:patient_phone_number, phone_type: "mobile")
    non_mobile_number = create(:patient_phone_number, phone_type: "landline")
    nil_type_number = create(:patient_phone_number, phone_type: nil)
    Flipper.enable(:force_mark_patient_mobile_numbers)

    MarkPatientMobileNumbers.call

    expect(mobile_number.reload.phone_type).to eq("mobile")
    expect(non_mobile_number.reload.phone_type).to eq("mobile")
    expect(nil_type_number.reload.phone_type).to eq("mobile")

    Flipper.disable(:force_mark_patient_mobile_numbers)
  end

  it "doesn't touch mobile numbers" do
    mobile_number = create(:patient_phone_number, phone_type: "mobile")
    Flipper.enable(:force_mark_patient_mobile_numbers)

    expect { MarkPatientMobileNumbers.call }.not_to change { mobile_number.reload.updated_at }

    Flipper.disable(:force_mark_patient_mobile_numbers)
  end

  it "does nothing if feature flag is not set" do
    non_mobile_number = create(:patient_phone_number, phone_type: "landline")
    nil_type_number = create(:patient_phone_number, phone_type: nil)

    MarkPatientMobileNumbers.call

    expect(non_mobile_number.reload.phone_type).to eq("landline")
    expect(nil_type_number.reload.phone_type).to eq(nil)
  end
end
