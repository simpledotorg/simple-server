require "rails_helper"

describe MarkPatientMobileNumbers, type: :model do
  it "marks non-mobile patient phone numbers as mobile" do
    mobile_number = create(:patient_phone_number, phone_type: "mobile")
    non_mobile_number = create(:patient_phone_number, phone_type: "landline")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("FORCE_MARK_PATIENT_MOBILE_NUMBERS").and_return "true"

    MarkPatientMobileNumbers.call

    expect(mobile_number.reload.phone_type).to eq("mobile")
    expect(non_mobile_number.reload.phone_type).to eq("mobile")
  end

  it "doesn't touch mobile numbers" do
    mobile_number = create(:patient_phone_number, phone_type: "mobile")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("FORCE_MARK_PATIENT_MOBILE_NUMBERS").and_return "true"

    expect { MarkPatientMobileNumbers.call }.not_to change { mobile_number.reload.updated_at }
  end

  it "does nothing if config is not set" do
    non_mobile_number = create(:patient_phone_number, phone_type: "landline")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("FORCE_MARK_PATIENT_MOBILE_NUMBERS").and_return "something else"

    expect { MarkPatientMobileNumbers.call }.not_to change { non_mobile_number.reload.phone_type }
  end
end
