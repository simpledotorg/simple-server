require "rails_helper"

RSpec.describe SeedPatients do
  it "works" do
    facilities = create_list(:facility, 2, facility_size: "community")
    facilities.each do |f|
      create(:user, registration_facility: f, role: ENV["SEED_GENERATED_ACTIVE_USER_ROLE"])
    end

    seeder = SeedPatients.new(scale_factor: 0.01)
    expect(seeder).to receive(:patients_to_create).and_return(3).twice
    expect(seeder).to receive(:blood_pressures_to_create).and_return(3).at_least(1).times
    expect {
      seeder.call
    }.to change { Patient.count }.by(6)
      .and change { BloodPressure.count }.by(18)
  end
end
