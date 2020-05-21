require "rails_helper"

RSpec.describe Facility, type: :model do
  describe "Associations" do
    it { should have_many(:users) }
    it { should have_many(:blood_pressures).through(:encounters).source(:blood_pressures) }
    it { should have_many(:blood_sugars).through(:encounters).source(:blood_sugars) }
    it { should have_many(:prescription_drugs) }
    it { should have_many(:patients).through(:encounters) }
    it { should have_many(:appointments) }

    it { should have_many(:registered_patients).class_name("Patient").with_foreign_key("registration_facility_id") }

    context "patients" do
      it "has distinct patients" do
        facility = create(:facility)
        dm_patient = create(:patient, :diabetes)
        htn_patient = create(:patient)

        create(:blood_sugar, :with_encounter, facility: facility, patient: dm_patient)
        create(:blood_sugar, :with_encounter, facility: facility, patient: htn_patient)
        create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient)
        create(:blood_pressure, :with_encounter, facility: facility, patient: dm_patient)

        expect(facility.patients.count).to eq(2)
      end
    end

    it { should belong_to(:facility_group).optional }
    it { should delegate_method(:follow_ups_by_period).to(:patients).with_prefix(:patient) }
  end

  describe "Delegates" do
    context "#patient_follow_ups_by_period" do
      it "counts follow_ups across HTN and DM" do
        registration_date = Time.new(2018, 4, 8)
        first_follow_up_date = registration_date + 1.month
        second_follow_up_date = first_follow_up_date + 1.month

        facility = create(:facility)
        dm_patient = create(:patient, :diabetes, recorded_at: registration_date)
        htn_patient = create(:patient, recorded_at: registration_date)

        create(:blood_sugar, :with_encounter, facility: facility, patient: dm_patient, recorded_at: first_follow_up_date)
        create(:blood_sugar, :with_encounter, facility: facility, patient: htn_patient, recorded_at: first_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient, recorded_at: second_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: dm_patient, recorded_at: second_follow_up_date)

        expected_output = {
          first_follow_up_date.to_date.beginning_of_month => 2,
          second_follow_up_date.to_date.beginning_of_month => 2
        }

        expect(facility.patient_follow_ups_by_period(:month).count).to eq(expected_output)
      end
    end

    context "#hypertension_follow_ups_by_period" do
      it "counts follow_ups only for hypertensive patients" do
        registration_date = Time.new(2018, 4, 8)
        first_follow_up_date = registration_date + 1.month
        second_follow_up_date = first_follow_up_date + 1.month

        facility = create(:facility)
        dm_patient = create(:patient, :diabetes, recorded_at: registration_date)
        htn_patient = create(:patient, recorded_at: registration_date)

        create(:blood_sugar, :with_encounter, facility: facility, patient: dm_patient, recorded_at: first_follow_up_date)
        create(:blood_sugar, :with_encounter, facility: facility, patient: htn_patient, recorded_at: first_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient, recorded_at: second_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: dm_patient, recorded_at: second_follow_up_date)

        expected_output = {
          second_follow_up_date.to_date.beginning_of_month => 1
        }

        expect(facility.hypertension_follow_ups_by_period(:month).count).to eq(expected_output)
      end
    end

    context "#diabetes_follow_ups_by_period" do
      it "counts follow_ups only for diabetic patients" do
        registration_date = Time.new(2018, 4, 8)
        first_follow_up_date = registration_date + 1.month
        second_follow_up_date = first_follow_up_date + 1.month

        facility = create(:facility)
        dm_patient = create(:patient, :diabetes, recorded_at: registration_date)
        htn_patient = create(:patient, recorded_at: registration_date)

        create(:blood_sugar, :with_encounter, facility: facility, patient: dm_patient, recorded_at: first_follow_up_date)
        create(:blood_sugar, :with_encounter, facility: facility, patient: htn_patient, recorded_at: first_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient, recorded_at: second_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: dm_patient, recorded_at: second_follow_up_date)

        expected_output = {
          first_follow_up_date.to_date.beginning_of_month => 1
        }

        expect(facility.diabetes_follow_ups_by_period(:month).count).to eq(expected_output)
      end
    end
  end

  describe "Validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:district) }
    it { should validate_presence_of(:state) }
    it { should validate_presence_of(:country) }
    it { should validate_numericality_of(:pin) }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe "#cohort_analytics" do
    it "considers only registered hypertensive patients" do
      facility = create(:facility)

      _non_htn_patients = create_list(:patient, 2, :without_hypertension, registration_facility: facility)
      htn_patients = create_list(:patient, 2, registration_facility: facility)

      expect(CohortAnalyticsQuery).to receive(:new).with(match_array(htn_patients)).and_call_original

      facility.cohort_analytics(:month, 3)
    end
  end
end
