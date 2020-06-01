require "rails_helper"
require "tasks/scripts/clean_ancient_dates"

RSpec.describe CleanAncientDates do
  describe ".call" do
    it "cleans ancient blood pressures and blood sugars" do
      ancient_date = Date.new(200, 1, 1)

      patient = create(:patient, recorded_at: ancient_date)

      ancient_blood_pressure = create(:blood_pressure, patient: patient, recorded_at: ancient_date)
      ancient_blood_sugar = create(:blood_sugar, patient: patient, recorded_at: ancient_date)

      normal_blood_pressure = create(:blood_pressure, patient: patient)
      normal_blood_sugar = create(:blood_sugar, patient: patient)

      CleanAncientDates.call(verbose: false)
      patient.reload

      expect(patient.blood_pressures).to include(normal_blood_pressure)
      expect(patient.blood_sugars).to include(normal_blood_sugar)

      expect(patient.blood_pressures).not_to include(ancient_blood_pressure)
      expect(patient.blood_sugars).not_to include(ancient_blood_sugar)
    end

    it "updates the patient's `recorded_at` to the earliest observation" do
      ancient_date = Date.new(200, 1, 1)
      registration_date = Date.new(2020, 1, 1)

      patient = create(:patient, recorded_at: ancient_date)

      create(:blood_pressure, patient: patient, recorded_at: ancient_date)
      create(:blood_sugar, patient: patient, recorded_at: ancient_date)

      create(:blood_pressure, patient: patient, recorded_at: registration_date)
      create(:blood_sugar, patient: patient, recorded_at: registration_date + 30.days)

      CleanAncientDates.call(verbose: false)

      expect(patient.reload.recorded_at).to eq(registration_date)
    end

    it "updates the patient's `recorded_at` when no observations are present" do
      ancient_date = Date.new(200, 1, 1)
      registration_date = Date.new(2020, 1, 1)

      patient = create(:patient, recorded_at: ancient_date, device_created_at: registration_date)

      CleanAncientDates.call(verbose: false)

      expect(patient.reload.recorded_at).to eq(registration_date)
    end

    context "dryrun" do
      it "does not mutate records" do
        ancient_date = Date.new(200, 1, 1)

        patient = create(:patient, recorded_at: ancient_date)

        ancient_blood_pressure = create(:blood_pressure, patient: patient, recorded_at: ancient_date)
        ancient_blood_sugar = create(:blood_sugar, patient: patient, recorded_at: ancient_date)

        normal_blood_pressure = create(:blood_pressure, patient: patient)
        normal_blood_sugar = create(:blood_sugar, patient: patient)

        CleanAncientDates.call(verbose: false, dryrun: true)
        patient.reload

        expect(patient.blood_pressures).to include(normal_blood_pressure, ancient_blood_pressure)
        expect(patient.blood_sugars).to include(normal_blood_sugar, ancient_blood_sugar)
      end
    end
  end
end
