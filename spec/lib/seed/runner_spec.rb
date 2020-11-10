require "rails_helper"

RSpec.describe Seed::Runner do
  it "works" do
    facilities = create_list(:facility, 2, facility_size: "community")
    facilities.each do |f|
      create(:user, registration_facility: f, role: ENV["SEED_GENERATED_ACTIVE_USER_ROLE"])
    end

    seeder = Seed::Runner.new(scale_factor: 0.01)
    expect(seeder).to receive(:patients_to_create).and_return(3).twice
    expect(seeder).to receive(:blood_pressures_to_create).and_return(3).at_least(1).times
    expect {
      seeder.call
    }.to change { Patient.count }.by(6)
      .and change { BloodPressure.count }.by(18)
      .and change { Encounter.count }.by(18)
      .and change { Observation.count }.by(18)
    expect(facilities.first.blood_pressures.count).to eq(9)
  end

  it "returns how many records are created" do
    facilities = create_list(:facility, 2, facility_size: "community")
    facilities.each do |f|
      create(:user, registration_facility: f, role: ENV["SEED_GENERATED_ACTIVE_USER_ROLE"])
    end

    seeder = Seed::Runner.new(scale_factor: 0.01)
    expect(seeder).to receive(:patients_to_create).and_return(3).twice
    expect(seeder).to receive(:blood_pressures_to_create).and_return(3).at_least(1).times
    result = seeder.call
    facilities.each { |f| expect(f.patients.size).to eq(3) }
    facilities.pluck(:slug).each do |slug|
      expect(result[slug][:blood_pressure]).to eq(9)
      expect(result[slug][:observation]).to eq(9)
      expect(result[slug][:encounter]).to eq(9)
      expect(result[slug][:appointment]).to eq(3)
    end
  end

  it "can create a reasonable data set in under 20 seconds" do
    facilities = create_list(:facility, 5, facility_size: "community")
    facilities.each do |f|
      create(:user, registration_facility: f, role: ENV["SEED_GENERATED_ACTIVE_USER_ROLE"])
    end

    time = Benchmark.ms {
      seeder = Seed::Runner.new(scale_factor: 0.01)
      expect(seeder).to receive(:patients_to_create).and_return(25).at_least(2).times
      expect(seeder).to receive(:blood_pressures_to_create).and_return(25).at_least(1).times
      seeder.call
    }
    time_in_seconds = time / 1000
    puts "#{time_in_seconds} seconds"
    expect(time_in_seconds).to be < 20
  end
end
