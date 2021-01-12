require "rails_helper"

RSpec.describe Seed::PatientSeeder do
  it "creates patients and related objects" do
    facility = create(:facility)
    user = create(:user)

    expect {
      Seed::PatientSeeder.call(facility, user, config: Seed::Config.new, logger: logger)
    }.to change { Patient.count }.by(4)
      .and change { Address.count }.by(4)
      .and change { MedicalHistory.count }.by(4)
      .and change { PatientBusinessIdentifier.count }.by(4)
      .and change { PatientPhoneNumber.count }.by(4)
      .and change { Facility.count }.by(0)
      .and change { User.count }.by(0)
  end
end
