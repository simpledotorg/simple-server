require "rails_helper"

RSpec.describe SeedPatients do
  it "works" do
    create_list(:user, 2, role: ENV["SEED_GENERATED_ACTIVE_USER_ROLE"])
    expect {
      SeedPatients.new(patients_to_create: 3, bps_to_create: 2).call
    }.to change { Patient.count }.by(6)
      .and change { BloodPressure.count }.by(12)
  end
end
