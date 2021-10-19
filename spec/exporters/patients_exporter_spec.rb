require "rails_helper"

RSpec.describe PatientsExporter, type: :model do
  include QuarterHelper

  around do |example|
    with_reporting_time_zone { example.run }
  end

  let!(:facility) { create(:facility) }
  let!(:registration_facility) { create(:facility) }
  let!(:patient) {
    create(:patient,
      assigned_facility: facility,
      registration_facility: registration_facility,
      status: "dead",
      address: create(:address, village_or_colony: Faker::Address.city)) # need a different village and zone
  }
  let!(:blood_pressure) { create(:blood_pressure, :with_encounter, :critical, facility: facility, patient: patient) }
  let!(:blood_sugar) { create(:blood_sugar, :fasting, :with_encounter, facility: facility, patient: patient) }
  let!(:appointment) { create(:appointment, :overdue, facility: facility, patient: patient) }
  let!(:prescription_drug_1) { create(:prescription_drug, patient: patient) }
  let!(:prescription_drug_2) { create(:prescription_drug, patient: patient) }
  let!(:prescription_drug_3) { create(:prescription_drug, :deleted, patient: patient) }

  let!(:old_blood_pressure) { create(:blood_pressure, recorded_at: 1.year.ago, patient: patient) }
  let!(:old_appointment) {
    create(
      :appointment,
      :overdue,
      facility: facility,
      patient: patient,
      scheduled_date: appointment.scheduled_date - 5.days
    )
  }
  let!(:old_bp_passport) {
    create(
      :patient_business_identifier,
      identifier_type: "simple_bp_passport",
      device_created_at: 1.year.ago,
      patient: patient
    )
  }

  let(:headers) do
    [
      "Registration Date",
      "Registration Quarter",
      "Patient Name",
      "Patient Age",
      "Patient Gender",
      "Patient Status",
      "Patient Phone Number",
      "Patient Street Address",
      "Patient Village/Colony",
      "Patient District",
      "Patient Zone",
      "Patient State",
      "Preferred Facility Name",
      "Preferred Facility Type",
      "Preferred Facility District",
      "Preferred Facility State",
      "Registration Facility Name",
      "Registration Facility Type",
      "Registration Facility District",
      "Registration Facility State",
      "Diagnosed with Hypertension",
      "Diagnosed with Diabetes",
      "Latest BP Date",
      "Latest BP Systolic",
      "Latest BP Diastolic",
      "Latest BP Quarter",
      "Latest BP Facility Name",
      "Latest BP Facility Type",
      "Latest BP Facility District",
      "Latest BP Facility State",
      "Latest Blood Sugar Date",
      "Latest Blood Sugar Value",
      "Latest Blood Sugar Type",
      "Follow-up Facility",
      "Follow-up Date",
      "Days Overdue",
      "Risk Level",
      "BP Passport ID",
      "Simple Patient ID",
      "Medication 1",
      "Dosage 1",
      "Medication 2",
      "Dosage 2",
      "Medication 3",
      "Dosage 3",
      "Medication 4",
      "Dosage 4",
      "Medication 5",
      "Dosage 5"
    ]
  end

  let(:fields) do
    [
      I18n.l(patient.recorded_at.to_date),
      quarter_string(patient.recorded_at),
      patient.full_name,
      patient.current_age,
      patient.gender.capitalize,
      "Died",
      patient.phone_numbers.last&.number,
      patient.address.street_address,
      patient.address.village_or_colony,
      patient.address.district,
      patient.address.zone,
      patient.address.state,
      facility.name,
      facility.facility_type,
      facility.district,
      facility.state,
      registration_facility.name,
      registration_facility.facility_type,
      registration_facility.district,
      registration_facility.state,
      "no",
      "yes",
      I18n.l(blood_pressure.recorded_at.to_date),
      blood_pressure.systolic,
      blood_pressure.diastolic,
      quarter_string(blood_pressure.recorded_at),
      blood_pressure.facility.name,
      blood_pressure.facility.facility_type,
      blood_pressure.facility.district,
      blood_pressure.facility.state,
      I18n.l(blood_sugar.recorded_at.to_date),
      "#{blood_sugar.blood_sugar_value} mg/dL",
      "Fasting",
      appointment.facility.name,
      appointment.scheduled_date.to_s(:rfc822),
      appointment.days_overdue,
      "High",
      patient.latest_bp_passport&.shortcode,
      patient.id,
      prescription_drug_2.name,
      prescription_drug_2.dosage,
      prescription_drug_1.name,
      prescription_drug_1.dosage
    ]
  end

  before do
    allow(patient).to receive(:high_risk?).and_return(true)
    allow(Rails.application.config.country).to receive(:[]).with(:patient_line_list_show_zone).and_return(true)
    blood_sugar.update!(encounter: blood_pressure.encounter)
    patient.medical_history.update!(hypertension: "no", diabetes: "yes")
    MaterializedPatientSummary.refresh
  end

  describe "#csv" do
    it "generates a CSV of patient records" do
      Timecop.freeze do
        timestamp = ["Report generated at:", Time.current]

        actual_csv = timestamp.to_csv + headers.to_csv + fields.to_csv
        expect(subject.csv(Patient.all).to_s.strip).to eq(actual_csv.to_s.strip)
      end
    end

    it "generates a blank CSV (only headers) if no patients exist" do
      Timecop.freeze do
        timestamp = ["Report generated at:", Time.current]

        expect(subject.csv(Patient.none)).to eq(timestamp.to_csv + headers.to_csv)
      end
    end

    it "does not include the zone column if the country config is set to false" do
      allow(Rails.application.config.country).to receive(:[]).with(:patient_line_list_show_zone).and_return(false)

      expect(subject.csv_headers).not_to include("Patient #{Address.human_attribute_name :zone}")
      expect(subject.csv_fields(MaterializedPatientSummary.find_by(id: patient))).not_to include(patient.address.zone)
    end

    it "includes blood sugars from other visits" do
      blood_sugar.destroy
      _other_blood_sugar = create(:blood_sugar, :fasting, :with_encounter, facility: facility, patient: patient)
      MaterializedPatientSummary.refresh

      patient_summary = MaterializedPatientSummary.find_by(id: patient)
      expect(subject.csv_fields(patient_summary)).to include("#{blood_sugar.blood_sugar_value} mg/dL")
      expect(subject.csv_fields(patient_summary)).to include("Fasting")
    end
  end
end
