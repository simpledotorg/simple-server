require "rails_helper"

describe MaterializedPatientSummary, type: :model do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  subject(:patient_summary) { MaterializedPatientSummary.find(patient.id) }

  let(:may_2019) { DateTime.new(2019, 5, 1) }
  let(:feb_2019) { DateTime.new(2019, 2, 1) }
  let(:jan_2019) { DateTime.new(2019, 1, 1) }
  let(:old_quarter) { "2019 Q1" }
  let(:new_quarter) { "2019 Q2" }
  let(:user) { create(:admin, :power_user) }
  let(:facility) { create(:facility) }

  # We create a bunch of related objects here to ensure the Materialized view properly rolls things up.
  # We _do not_ split things out into individual let blocks, because it makes detangling dependancies too difficult.
  let(:patient) do
    patient = create(:patient, registration_facility: facility, recorded_at: jan_2019, registration_user: user)
    _old_phone = create(:patient_phone_number, patient: patient, device_created_at: jan_2019)
    _new_phone = create(:patient_phone_number, patient: patient, device_created_at: may_2019)
    _old_passport = create(:patient_business_identifier, patient: patient, device_created_at: jan_2019)
    @latest_bp_1 = create(:blood_pressure, patient: patient, facility: facility, recorded_at: may_2019, user: user, systolic: 110, diastolic: 70)
    @latest_bp_2 = create(:blood_pressure, patient: patient, facility: facility, recorded_at: feb_2019, user: user)
    @latest_bp_3 = create(:blood_pressure, patient: patient, facility: facility, recorded_at: jan_2019, user: user)
    @blood_sugar = create(:blood_sugar, patient: patient, facility: facility, recorded_at: may_2019, user: user,
                                        blood_sugar_type: "random", blood_sugar_value: 100)
    patient
  end

  attr_reader :latest_bp_1
  attr_reader :latest_bp_2
  attr_reader :latest_bp_3
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
      expect(patient_summary.recorded_at).to eq(jan_2019)
    end

    it "includes registration facility details", :aggregate_failures do
      expect(patient_summary.registration_facility_name).to eq(patient.registration_facility.name)
      expect(patient_summary.registration_facility_type).to eq(patient.registration_facility.facility_type)
      expect(patient_summary.registration_facility_district).to eq(patient.registration_facility.district)
      expect(patient_summary.registration_facility_state).to eq(patient.registration_facility.state)
    end

    it "includes latest BP details" do
      upcoming_appointment = create(:appointment, patient: patient, device_created_at: latest_bp_1.recorded_at)
      refresh_view
      expect(patient_summary.latest_blood_pressure_1_systolic).to eq(latest_bp_1.systolic)
      expect(patient_summary.latest_blood_pressure_1_diastolic).to eq(latest_bp_1.diastolic)
      expect(patient_summary.latest_blood_pressure_1_recorded_at).to eq(latest_bp_1.recorded_at)
      expect(patient_summary.latest_blood_pressure_1_facility_name).to eq(latest_bp_1.facility.name)
      expect(patient_summary.latest_blood_pressure_1_facility_type).to eq(latest_bp_1.facility.facility_type)
      expect(patient_summary.latest_blood_pressure_1_district).to eq(latest_bp_1.facility.district)
      expect(patient_summary.latest_blood_pressure_1_state).to eq(latest_bp_1.facility.state)
      expect(patient_summary.latest_blood_pressure_1_follow_up_facility_name).to eq(upcoming_appointment.facility.name)
      expect(patient_summary.latest_blood_pressure_1_follow_up_date).to eq(upcoming_appointment.scheduled_date)
      expect(patient_summary.latest_blood_pressure_1_follow_up_days).to eq(upcoming_appointment.follow_up_days)
    end

    it "includes second latest BP details" do
      expect(patient_summary.latest_blood_pressure_2_systolic).to eq(latest_bp_2.systolic)
      expect(patient_summary.latest_blood_pressure_2_diastolic).to eq(latest_bp_2.diastolic)
      expect(patient_summary.latest_blood_pressure_2_recorded_at).to eq(latest_bp_2.recorded_at)
      expect(patient_summary.latest_blood_pressure_2_facility_name).to eq(latest_bp_2.facility.name)
      expect(patient_summary.latest_blood_pressure_2_facility_type).to eq(latest_bp_2.facility.facility_type)
      expect(patient_summary.latest_blood_pressure_2_district).to eq(latest_bp_2.facility.district)
      expect(patient_summary.latest_blood_pressure_2_state).to eq(latest_bp_2.facility.state)
    end

    it "includes third latest BP details" do
      expect(patient_summary.latest_blood_pressure_3_systolic).to eq(latest_bp_3.systolic)
      expect(patient_summary.latest_blood_pressure_3_diastolic).to eq(latest_bp_3.diastolic)
      expect(patient_summary.latest_blood_pressure_3_recorded_at).to eq(latest_bp_3.recorded_at)
      expect(patient_summary.latest_blood_pressure_3_facility_name).to eq(latest_bp_3.facility.name)
      expect(patient_summary.latest_blood_pressure_3_facility_type).to eq(latest_bp_3.facility.facility_type)
      expect(patient_summary.latest_blood_pressure_3_district).to eq(latest_bp_3.facility.district)
      expect(patient_summary.latest_blood_pressure_3_state).to eq(latest_bp_3.facility.state)
    end

    it "includes latest drugs prescribed as of when a BP was recorded" do
      bp_recorded_at = latest_bp_1.recorded_at

      earliest_prescription_drug = create(:prescription_drug, patient: patient, device_created_at: bp_recorded_at - 3.months, name: "Drug A")
      protocol_drug = create(:prescription_drug, patient: patient, device_created_at: bp_recorded_at - 2.months, is_protocol_drug: true, name: "Drug B")
      protocol_drug_2 = create(:prescription_drug, patient: patient, device_created_at: bp_recorded_at - 2.months, is_protocol_drug: true, name: "Drug C")
      # Drugs deleted before BP and those prescribed after BP should not show up in the list of prescribed drugs for a BP
      _drug_prescribed_after_bp_recorded = create(:prescription_drug, patient: patient, device_created_at: bp_recorded_at + 1.month, name: "Drug D")
      _drug_deleted_before_bp_recorded = create(:prescription_drug, patient: patient, is_deleted: true, device_created_at: bp_recorded_at - 2.months, device_updated_at: bp_recorded_at - 1.month, name: "Drug E")
      drug_deleted_after_bp_recorded = create(:prescription_drug, patient: patient, is_deleted: true, device_created_at: bp_recorded_at - 2.months, device_updated_at: bp_recorded_at + 1.month, name: "Drug F")
      drug_deleted_after_bp_recorded_2 = create(:prescription_drug, patient: patient, is_deleted: true, device_created_at: bp_recorded_at - 2.months, device_updated_at: bp_recorded_at + 2.months, name: "Drug G")
      other_drug_1 = create(:prescription_drug, patient: patient, device_created_at: bp_recorded_at - 15.days, name: "Drug H")
      other_drug_2 = create(:prescription_drug, patient: patient, device_created_at: bp_recorded_at - 15.days, name: "Drug I")
      other_drugs_name = [other_drug_1, other_drug_2].map { |drug| "#{drug.name}-#{drug.dosage}" }.join(", ")

      refresh_view

      # Prescription drugs are sorted by whether they are protocol drugs, by name, and finally the date of prescription
      expect(patient_summary.latest_blood_pressure_1_prescription_drug_1_name).to eq(protocol_drug.name)
      expect(patient_summary.latest_blood_pressure_1_prescription_drug_1_dosage).to eq(protocol_drug.dosage)
      expect(patient_summary.latest_blood_pressure_1_prescription_drug_2_name).to eq(protocol_drug_2.name)
      expect(patient_summary.latest_blood_pressure_1_prescription_drug_2_dosage).to eq(protocol_drug_2.dosage)
      expect(patient_summary.latest_blood_pressure_1_prescription_drug_3_name).to eq(earliest_prescription_drug.name)
      expect(patient_summary.latest_blood_pressure_1_prescription_drug_3_dosage).to eq(earliest_prescription_drug.dosage)
      expect(patient_summary.latest_blood_pressure_1_prescription_drug_4_name).to eq(drug_deleted_after_bp_recorded.name)
      expect(patient_summary.latest_blood_pressure_1_prescription_drug_4_dosage).to eq(drug_deleted_after_bp_recorded.dosage)
      expect(patient_summary.latest_blood_pressure_1_prescription_drug_5_name).to eq(drug_deleted_after_bp_recorded_2.name)
      expect(patient_summary.latest_blood_pressure_1_prescription_drug_5_dosage).to eq(drug_deleted_after_bp_recorded_2.dosage)
      expect(patient_summary.latest_blood_pressure_1_other_prescription_drugs).to eq(other_drugs_name)
    end

    it "checks if prescription drugs have been changed since the last BP check" do
      _prescription_drug_1 = create(:prescription_drug, patient: patient, device_created_at: latest_bp_3.recorded_at)
      _prescription_drug_2 = create(:prescription_drug, patient: patient, device_created_at: latest_bp_1.recorded_at)

      refresh_view

      expect(patient_summary.latest_blood_pressure_1_medication_updated).to be true
      expect(patient_summary.latest_blood_pressure_2_medication_updated).to be false
      expect(patient_summary.latest_blood_pressure_3_medication_updated).to be nil
    end

    it "includes latest blood sugar measurements", :aggregate_failures do
      expect(patient_summary.latest_blood_sugar_1_blood_sugar_type).to eq(blood_sugar.blood_sugar_type)
      expect(patient_summary.latest_blood_sugar_1_blood_sugar_value).to eq(blood_sugar.blood_sugar_value)
    end

    it "includes latest blood sugar date" do
      expect(patient_summary.latest_blood_sugar_1_recorded_at).to eq(blood_sugar.recorded_at)
    end

    it "includes latest blood sugar facility details", :aggregate_failures do
      expect(patient_summary.latest_blood_sugar_1_facility_name).to eq(blood_sugar.facility.name)
      expect(patient_summary.latest_blood_sugar_1_facility_type).to eq(blood_sugar.facility.facility_type)
      expect(patient_summary.latest_blood_sugar_1_district).to eq(blood_sugar.facility.district)
      expect(patient_summary.latest_blood_sugar_1_state).to eq(blood_sugar.facility.state)
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

  xdescribe "#ltfu?" do
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
