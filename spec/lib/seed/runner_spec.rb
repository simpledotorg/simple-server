require "rails_helper"

RSpec.describe Seed::Runner do
  let(:config) { Seed::Config.new }

  it "creates expected number of valid records from fast seed config" do
    facilities = create_list(:facility, 2, facility_size: "community")
    facilities.each do |f|
      create(:user, registration_facility: f, role: ENV["SEED_GENERATED_ACTIVE_USER_ROLE"])
    end

    expected_patients = config.max_patients_to_create[:community]
    expected_bps = config.max_bps_to_create * expected_patients * facilities.size
    expected_blood_sugars = config.max_blood_sugars_to_create * expected_patients * facilities.size
    expected_encounters = expected_bps + expected_blood_sugars
    seeder = Seed::Runner.new
    expect {
      seeder.call
    }.to change { Patient.count }.by(6)
      .and change { Address.count }.by(6)
      .and change { PatientBusinessIdentifier.count }.by(6)
      .and change { MedicalHistory.count }.by(6)
      .and change { BloodPressure.count }.by(expected_bps)
      .and change { BloodSugar.count }.by(expected_blood_sugars)
      .and change { Encounter.count }.by(expected_encounters)
      .and change { Observation.count }.by(expected_encounters)
      .and change { Organization.count }.by(1)
    Patient.all.each do |patient|
      expect(patient).to be_valid
      expect(patient.medical_history).to be_valid
      expect(patient.address).to be_valid
      patient.blood_pressures.each do |bp|
        expect(bp).to be_valid
        expect(bp.created_at).to be < Date.current
        expect(bp.updated_at).to be < Date.current
      end
    end
  end

  it "returns how many records are created per facility and total" do
    facilities = create_list(:facility, 2, facility_size: "community")
    facilities.each do |f|
      create(:user, registration_facility: f, role: ENV["SEED_GENERATED_ACTIVE_USER_ROLE"])
    end

    expected_bps_per_facility = config.max_bps_to_create * config.max_patients_to_create.fetch(:community)
    expected_blood_sugars_per_facility = config.max_blood_sugars_to_create * config.max_patients_to_create.fetch(:community)
    expected_encounters_per_facility = expected_bps_per_facility + expected_blood_sugars_per_facility
    seeder = Seed::Runner.new
    result, total_results = seeder.call
    facilities.each { |f| expect(f.patients.size).to eq(3) }
    facilities.pluck(:slug).each do |slug|
      expect(result[slug][:address]).to eq(3)
      expect(result[slug][:patient]).to eq(3)
      expect(result[slug][:blood_pressure]).to eq(expected_bps_per_facility)
      expect(result[slug][:observation]).to eq(expected_encounters_per_facility)
      expect(result[slug][:encounter]).to eq(expected_encounters_per_facility)
      expect(result[slug][:appointment]).to eq(3)
    end
    expect(total_results[:facility]).to eq(0)
    expect(total_results[:patient]).to eq(6)
    expect(total_results[:blood_pressure]).to eq(expected_bps_per_facility * 2)
    expect(total_results[:blood_sugar]).to eq(expected_blood_sugars_per_facility * 2)
    expect(total_results[:observation]).to eq(expected_encounters_per_facility * 2)
    expect(total_results[:encounter]).to eq(expected_encounters_per_facility * 2)
  end

  it "can create a small data set quickly" do
    skip if ENV["CI"]

    max_time = 7
    time = Benchmark.ms {
      seeder = Seed::Runner.new
      seeder.call
    }
    time_in_seconds = time / 1000
    expect(time_in_seconds).to be < max_time
  end
end
