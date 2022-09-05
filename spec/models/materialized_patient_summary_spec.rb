require "rails_helper"

describe MaterializedPatientSummary, type: :model do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  subject(:patient_summary) { MaterializedPatientSummary.find(patient.id) }

  let(:old_date) { DateTime.new(2019, 1, 1) }
  let(:new_date) { DateTime.new(2019, 5, 1) }
  let(:old_quarter) { "2019 Q1" }
  let(:new_quarter) { "2019 Q2" }
  let(:user) { create(:admin, :power_user) }
  let(:facility) { create(:facility) }

  # We create a bunch of related objects here to ensure the Materialized view properly rolls things up.
  # We _do not_ split things out into individual let blocks, because it makes detangling dependancies too difficult.
  let(:patient) do
    patient = create(:patient, registration_facility: facility, recorded_at: old_date, registration_user: user)
    _old_bp = create(:blood_pressure, patient: patient, facility: facility, recorded_at: old_date, user: user)
    _old_phone = create(:patient_phone_number, patient: patient, device_created_at: old_date)
    _new_phone = create(:patient_phone_number, patient: patient, device_created_at: new_date)
    _old_passport = create(:patient_business_identifier, patient: patient, device_created_at: old_date)
    @new_bp = create(:blood_pressure, patient: patient, facility: facility, recorded_at: new_date, user: user, systolic: 110, diastolic: 70)
    @blood_sugar = create(:blood_sugar, patient: patient, facility: facility, recorded_at: new_date, user: user,
                                        blood_sugar_type: "random", blood_sugar_value: 100)
    patient
  end

  attr_reader :new_bp
  attr_reader :blood_sugar

  def refresh_view
    MaterializedPatientSummary.refresh
  end

  describe ".overdue scope" do
    it "includes overdue appointments and excludes non-overdue" do
      overdue_appointment = create(:appointment, :overdue, facility: facility, user: user)
      upcoming_appointment = create(:appointment, facility: facility, user: user)

      refresh_view

      expect(MaterializedPatientSummary.overdue.map(&:id)).to include(overdue_appointment.patient_id)
      expect(MaterializedPatientSummary.overdue.map(&:id)).not_to include(upcoming_appointment.patient_id)
    end
  end

  describe "Patient Summary details" do
    before do
      patient
      refresh_view
    end

    it "includes patient id and attributes" do
      expect(patient_summary.id).to eq(patient.id)
      expect(patient_summary.full_name).to eq(patient.full_name)
      expect(patient_summary.gender).to eq(patient.gender)
      expect(patient_summary.status).to eq(patient.status)
    end

    it "uses DOB as current age if present" do
      date_of_birth = 40.years.ago
      patient.update!(date_of_birth: date_of_birth)
      refresh_view

      expect(patient_summary.current_age).to eq(40)
    end

    it "calculates current_age if DOB is not present" do
      patient.update!(date_of_birth: nil, age: 50, age_updated_at: 13.months.ago)
      refresh_view

      expect(patient_summary.current_age).to eq(51)
    end

    it "includes patient address", :aggregate_failures do
      expect(patient_summary.village_or_colony).to eq(patient.address.village_or_colony)
      expect(patient_summary.district).to eq(patient.address.district)
      expect(patient_summary.state).to eq(patient.address.state)
    end

    it "includes registration date" do
      expect(patient_summary.recorded_at).to eq(old_date)
    end

    it "calculates registration quarter" do
      expect(patient_summary.registration_quarter).to eq(old_quarter)
    end

    it "includes registration facility details", :aggregate_failures do
      expect(patient_summary.registration_facility_name).to eq(patient.registration_facility.name)
      expect(patient_summary.registration_facility_type).to eq(patient.registration_facility.facility_type)
      expect(patient_summary.registration_district).to eq(patient.registration_facility.district)
      expect(patient_summary.registration_state).to eq(patient.registration_facility.state)
    end

    it "includes latest BP measurements", :aggregate_failures do
      expect(patient_summary.latest_blood_pressure_systolic).to eq(new_bp.systolic)
      expect(patient_summary.latest_blood_pressure_diastolic).to eq(new_bp.diastolic)
    end

    it "includes latest BP date" do
      expect(patient_summary.latest_blood_pressure_recorded_at).to eq(new_bp.recorded_at)
    end

    it "includes latest BP quarter" do
      expect(patient_summary.latest_blood_pressure_quarter).to eq(new_quarter)
    end

    it "includes latest BP facility details", :aggregate_failures do
      expect(patient_summary.latest_blood_pressure_facility_name).to eq(new_bp.facility.name)
      expect(patient_summary.latest_blood_pressure_facility_type).to eq(new_bp.facility.facility_type)
      expect(patient_summary.latest_blood_pressure_district).to eq(new_bp.facility.district)
      expect(patient_summary.latest_blood_pressure_state).to eq(new_bp.facility.state)
    end

    it "includes latest blood sugar measurements", :aggregate_failures do
      expect(patient_summary.latest_blood_sugar_type).to eq(blood_sugar.blood_sugar_type)
      expect(patient_summary.latest_blood_sugar_value).to eq(blood_sugar.blood_sugar_value)
    end

    it "includes latest blood sugar date" do
      expect(patient_summary.latest_blood_sugar_recorded_at).to eq(blood_sugar.recorded_at)
    end

    it "includes latest blood sugar quarter" do
      expect(patient_summary.latest_blood_sugar_quarter).to eq(new_quarter)
    end

    it "includes latest blood sugar facility details", :aggregate_failures do
      expect(patient_summary.latest_blood_sugar_facility_name).to eq(blood_sugar.facility.name)
      expect(patient_summary.latest_blood_sugar_facility_type).to eq(blood_sugar.facility.facility_type)
      expect(patient_summary.latest_blood_sugar_district).to eq(blood_sugar.facility.district)
      expect(patient_summary.latest_blood_sugar_state).to eq(blood_sugar.facility.state)
    end

    it "includes latest BP passport" do
      expect(patient_summary.latest_bp_passport).to eq(patient.latest_bp_passport)
    end

    it "includes latest BP passport number directly" do
      expect(patient_summary.latest_bp_passport_identifier).to eq(patient.latest_bp_passport.identifier)
    end
  end

  describe "Next appointment details" do
    let(:next_appointment) { create(:appointment, patient: patient, user: user, facility: facility) }

    before do
      next_appointment
      refresh_view
    end

    it "days overdue set to zero if not overdue" do
      expect(patient_summary.days_overdue).to eq(0)
    end

    it "days overdue is calculated if overdue" do
      next_appointment.update!(scheduled_date: 60.days.ago)
      refresh_view

      expect(patient_summary.reload.days_overdue).to eq(60)
    end

    it "includes next appointment date" do
      expect(patient_summary.next_scheduled_appointment_scheduled_date).to eq(next_appointment.scheduled_date)
    end

    it "includes next appointment date based on device_created_at" do
      create(:appointment, patient: patient, user: user, facility: facility,
             device_created_at: 10.days.ago, scheduled_date: next_appointment.scheduled_date - 10.days)

      expect(patient_summary.next_scheduled_appointment_scheduled_date).to eq(next_appointment.scheduled_date)
    end

    it "includes next appointment facility details", :aggregate_failures do
      expect(patient_summary.next_scheduled_appointment_facility_name).to eq(next_appointment.facility.name)
      expect(patient_summary.next_scheduled_appointment_facility_type).to eq(next_appointment.facility.facility_type)
      expect(patient_summary.next_scheduled_appointment_district).to eq(next_appointment.facility.district)
      expect(patient_summary.next_scheduled_appointment_state).to eq(next_appointment.facility.state)
    end

    it "doesn't include next appointment if there's no scheduled appointment" do
      next_appointment.update(status: :visited)
      refresh_view

      expect(patient_summary.reload.days_overdue).to eq(0)
    end
  end

  describe "Risk level" do
    it "returns 0 for patients recently overdue" do
      create(:appointment, scheduled_date: 29.days.ago, status: :scheduled, patient: patient)
      refresh_view

      expect(patient_summary.risk_level).to eq(0)
    end

    it "returns 1 for patients overdue with critical bp" do
      create(:blood_pressure, :critical, patient: patient)
      create(:appointment, scheduled_date: 31.days.ago, status: :scheduled, patient: patient)
      refresh_view

      expect(patient_summary.risk_level).to eq(1)
    end

    it "returns 1 for hypertensive bp patients with medical history risks" do
      patient.medical_history.delete
      create(:medical_history, :prior_risk_history, patient: patient)
      create(:blood_pressure, :hypertensive, patient: patient, facility: facility)
      create(:appointment, :overdue, patient: patient, facility: facility)
      refresh_view

      expect(patient_summary.risk_level).to eq(1)
    end

    it "returns 0 for patients overdue with only hypertensive bp" do
      create(:blood_pressure, :hypertensive, patient: patient, facility: facility)
      create(:appointment, :overdue, patient: patient, facility: facility)
      refresh_view

      expect(patient_summary.risk_level).to eq(0)
    end

    it "returns 0 for patients overdue with only medical risk history" do
      create(:medical_history, :prior_risk_history, patient: patient)
      create(:appointment, :overdue, patient: patient, facility: facility)
      refresh_view

      expect(patient_summary.risk_level).to eq(0)
    end

    it "returns 0 for patients overdue with hypertension" do
      create(:blood_pressure, :hypertensive, patient: patient, user: user, facility: facility)
      create(:appointment, :overdue, patient: patient, user: user, facility: facility)
      refresh_view

      expect(patient_summary.risk_level).to eq(0)
    end

    it "returns 0 for patients overdue with low risk" do
      create(:blood_pressure, :under_control, patient: patient, facility: facility, user: user)
      create(:appointment, scheduled_date: 2.years.ago, status: :scheduled, patient: patient, facility: facility, user: user)
      refresh_view

      expect(patient_summary.risk_level).to eq(0)
    end

    it "returns 1 for patients overdue with high blood sugar" do
      create(:blood_sugar, patient: patient, blood_sugar_type: :random, blood_sugar_value: 300, facility: facility, user: user)
      create(:appointment, scheduled_date: 31.days.ago, status: :scheduled, patient: patient, facility: facility, user: user)
      refresh_view

      expect(patient_summary.risk_level).to eq(1)
    end

    it "returns 'none' priority for patients overdue with normal blood sugar" do
      create(:blood_sugar, patient: patient, blood_sugar_type: :random, blood_sugar_value: 150, facility: facility, user: user)
      create(:appointment, :overdue, patient: patient, facility: facility, user: user)
      refresh_view

      expect(patient_summary.risk_level).to eq(0)
    end
  end

  describe "#ltfu?" do
    it "is true if patient was registered over a year ago without any BPs, blood sugars, prescription drugs or appointments recorded" do
      ltfu_patient = create(:patient, recorded_at: 365.days.ago)
      refresh_view

      expect(described_class.find(ltfu_patient.id)).to be_ltfu
    end

    it "is false if patient registered within the LTFU time" do
      not_ltfu_patient = create(:patient, recorded_at: 364.days.ago)
      refresh_view

      expect(described_class.find(not_ltfu_patient.id)).not_to be_ltfu
    end

    context "patient records a BP" do
      it "is false if patient recorded a BP within the LTFU time" do
        not_ltfu_patient = create(:patient, recorded_at: 365.days.ago)
        create(:blood_pressure, patient: not_ltfu_patient, recorded_at: 364.days.ago)
        refresh_view

        expect(described_class.find(not_ltfu_patient.id)).not_to be_ltfu
      end

      it "is true if patient's latest BP recorded is outside the LTFU time" do
        ltfu_patient = create(:patient, recorded_at: 365.days.ago)
        create(:blood_pressure, patient: ltfu_patient, recorded_at: 365.days.ago)
        refresh_view

        expect(described_class.find(ltfu_patient.id)).to be_ltfu
      end
    end

    context "patient records a blood sugar" do
      it "is false if patient recorded a blood sugar within the LTFU time" do
        not_ltfu_patient = create(:patient, recorded_at: 365.days.ago)
        create(:blood_sugar, patient: not_ltfu_patient, recorded_at: 364.days.ago)
        refresh_view

        expect(described_class.find(not_ltfu_patient.id)).not_to be_ltfu
      end

      it "is true if patient's latest blood sugar recorded is outside the LTFU time" do
        ltfu_patient = create(:patient, recorded_at: 365.days.ago)
        create(:blood_sugar, patient: ltfu_patient, recorded_at: 365.days.ago)
        refresh_view

        expect(described_class.find(ltfu_patient.id)).to be_ltfu
      end
    end

    context "patient records a PD" do
      it "is false if patient recorded a prescription drug within the LTFU time" do
        not_ltfu_patient = create(:patient, recorded_at: 365.days.ago)
        create(:prescription_drug, patient: not_ltfu_patient, device_created_at: 364.days.ago)
        refresh_view

        expect(described_class.find(not_ltfu_patient.id)).not_to be_ltfu
      end

      it "is true if patient's latest prescription drug recorded is outside the LTFU time" do
        ltfu_patient = create(:patient, recorded_at: 365.days.ago)
        create(:prescription_drug, patient: ltfu_patient, device_created_at: 365.days.ago)
        refresh_view

        expect(described_class.find(ltfu_patient.id)).to be_ltfu
      end
    end

    context "patient records an appointment" do
      it "is false if patient created an appointment within the LTFU time" do
        not_ltfu_patient = create(:patient, recorded_at: 365.days.ago)
        create(:appointment, patient: not_ltfu_patient, device_created_at: 364.days.ago)
        refresh_view

        expect(described_class.find(not_ltfu_patient.id)).not_to be_ltfu
      end

      it "is true if patient's latest appointment created is outside the LTFU time" do
        ltfu_patient = create(:patient, recorded_at: 365.days.ago)
        create(:appointment, patient: ltfu_patient, device_created_at: 365.days.ago)
        refresh_view

        expect(described_class.find(ltfu_patient.id)).to be_ltfu
      end
    end
  end
end
