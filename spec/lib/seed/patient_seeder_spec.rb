require "rails_helper"

RSpec.describe Seed::PatientSeeder do
  it "creates patients for a facility" do
    facility = create(:facility)
    user = create(:user)

    expect {
      Seed::PatientSeeder.call(facility, user, config: Seed::Config.new, logger: logger)
    }.to change { Patient.count }.by(4)
      .and change { Address.count }.by(4)
      .and change { PatientBusinessIdentifier.count }.by(4)
  end
end