require "rails_helper"

RSpec.describe PatientsWithHistoryExporter, type: :model do
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
      age: 50,
      status: "dead",
      address: create(:address, village_or_colony: Faker::Address.city)) # need a different village and zone
  }
  let!(:user) { patient.registration_user }
  let!(:bp_1) { create(:blood_pressure, :with_encounter, :critical, recorded_at: 2.months.ago, facility: facility, patient: patient, user: user) }
  let!(:blood_sugar) { create(:blood_sugar, :fasting, :with_encounter, recorded_at: 2.months.ago, facility: facility, patient: patient, user: user) }
  let!(:bp_1_follow_up) { create(:appointment, :overdue, device_created_at: 2.months.ago, scheduled_date: 40.days.ago, creation_facility: facility, patient: patient, user: user) }
  let!(:bp_2) { create(:blood_pressure, :with_encounter, recorded_at: 3.months.ago, facility: facility, patient: patient, user: user) }
  let!(:old_blood_sugar) { create(:blood_sugar, :with_encounter, recorded_at: 3.months.ago, facility: facility, patient: patient, user: user) }
  let!(:bp_2_follow_up) { create(:appointment, device_created_at: 3.months.ago, scheduled_date: 2.months.ago, creation_facility: facility, patient: patient, user: user) }
  let!(:bp_3) { create(:blood_pressure, :with_encounter, recorded_at: 4.months.ago, facility: facility, patient: patient, user: user) }
  let!(:bp_3_follow_up) { create(:appointment, device_created_at: 4.month.ago, scheduled_date: 3.months.ago, creation_facility: facility, patient: patient, user: user) }
  let!(:bp_4) { create(:blood_pressure, :with_encounter, recorded_at: 5.months.ago, facility: facility, patient: patient, user: user) }
  let(:old_prescription_drug) { create(:prescription_drug, device_created_at: 5.months.ago, facility: facility, patient: patient) }
  let!(:prescription_drugs) do
    [
      *create_list(:prescription_drug,
        4,
        :protocol,
        device_created_at: 3.months.ago,
        facility: facility,
        patient: patient).sort_by(&:name),
      *[create_list(:prescription_drug,
        2,
        device_created_at: 3.months.ago,
        facility: facility,
        patient: patient),
        old_prescription_drug].flatten.sort_by(&:name)
    ]
  end
  let(:headers) do
    [
      "Registration Date",
      "Registration Quarter",
      "Simple Patient ID",
      "BP Passport ID",
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
      "Risk Level",
      "Days Overdue For Next Follow-up",
      "BP 1 Date",
      "BP 1 Quarter",
      "BP 1 Systolic",
      "BP 1 Diastolic",
      "BP 1 Facility Name",
      "BP 1 Facility Type",
      "BP 1 Facility District",
      "BP 1 Facility State",
      "BP 1 Follow-up Facility",
      "BP 1 Follow-up Date",
      "BP 1 Follow up Days",
      "BP 1 Medication Titrated",
      "BP 1 Medication 1",
      "BP 1 Dosage 1",
      "BP 1 Medication 2",
      "BP 1 Dosage 2",
      "BP 1 Medication 3",
      "BP 1 Dosage 3",
      "BP 1 Medication 4",
      "BP 1 Dosage 4",
      "BP 1 Medication 5",
      "BP 1 Dosage 5",
      "BP 1 Other Medications",
      "BP 2 Date",
      "BP 2 Quarter",
      "BP 2 Systolic",
      "BP 2 Diastolic",
      "BP 2 Facility Name",
      "BP 2 Facility Type",
      "BP 2 Facility District",
      "BP 2 Facility State",
      "BP 2 Follow-up Facility",
      "BP 2 Follow-up Date",
      "BP 2 Follow up Days",
      "BP 2 Medication Titrated",
      "BP 2 Medication 1",
      "BP 2 Dosage 1",
      "BP 2 Medication 2",
      "BP 2 Dosage 2",
      "BP 2 Medication 3",
      "BP 2 Dosage 3",
      "BP 2 Medication 4",
      "BP 2 Dosage 4",
      "BP 2 Medication 5",
      "BP 2 Dosage 5",
      "BP 2 Other Medications",
      "BP 3 Date",
      "BP 3 Quarter",
      "BP 3 Systolic",
      "BP 3 Diastolic",
      "BP 3 Facility Name",
      "BP 3 Facility Type",
      "BP 3 Facility District",
      "BP 3 Facility State",
      "BP 3 Follow-up Facility",
      "BP 3 Follow-up Date",
      "BP 3 Follow up Days",
      "BP 3 Medication Titrated",
      "BP 3 Medication 1",
      "BP 3 Dosage 1",
      "BP 3 Medication 2",
      "BP 3 Dosage 2",
      "BP 3 Medication 3",
      "BP 3 Dosage 3",
      "BP 3 Medication 4",
      "BP 3 Dosage 4",
      "BP 3 Medication 5",
      "BP 3 Dosage 5",
      "BP 3 Other Medications",
      "Latest Blood Sugar Date",
      "Latest Blood Sugar Value",
      "Latest Blood Sugar Type"
    ]
  end
  let(:fields) do
    [
      I18n.l(patient.recorded_at.to_date),
      quarter_string(patient.recorded_at.to_date),
      patient.id,
      patient.latest_bp_passport&.shortcode,
      patient.full_name,
      patient.current_age.to_i,
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
      "High",
      bp_1_follow_up.days_overdue,
      I18n.l(bp_1.recorded_at.to_date),
      quarter_string(bp_1.recorded_at.to_date),
      bp_1.systolic,
      bp_1.diastolic,
      bp_1.facility.name,
      bp_1.facility.facility_type,
      bp_1.facility.district,
      bp_1.facility.state,
      bp_1_follow_up.facility.name,
      I18n.l(bp_1_follow_up.scheduled_date.to_date),
      bp_1_follow_up.follow_up_days,
      "No",
      prescription_drugs[0].name,
      prescription_drugs[0].dosage,
      prescription_drugs[1].name,
      prescription_drugs[1].dosage,
      prescription_drugs[2].name,
      prescription_drugs[2].dosage,
      prescription_drugs[3].name,
      prescription_drugs[3].dosage,
      prescription_drugs[4].name,
      prescription_drugs[4].dosage,
      "#{prescription_drugs[5].name}-#{prescription_drugs[5].dosage}, #{prescription_drugs[6].name}-#{prescription_drugs[6].dosage}",
      I18n.l(bp_2.recorded_at.to_date),
      quarter_string(bp_2.recorded_at.to_date),
      bp_2.systolic,
      bp_2.diastolic,
      bp_2.facility.name,
      bp_2.facility.facility_type,
      bp_2.facility.district,
      bp_2.facility.state,
      bp_2_follow_up.facility.name,
      I18n.l(bp_2_follow_up.scheduled_date),
      bp_2_follow_up.follow_up_days,
      "Yes",
      prescription_drugs[0].name,
      prescription_drugs[0].dosage,
      prescription_drugs[1].name,
      prescription_drugs[1].dosage,
      prescription_drugs[2].name,
      prescription_drugs[2].dosage,
      prescription_drugs[3].name,
      prescription_drugs[3].dosage,
      prescription_drugs[4].name,
      prescription_drugs[4].dosage,
      "#{prescription_drugs[5].name}-#{prescription_drugs[5].dosage}, #{prescription_drugs[6].name}-#{prescription_drugs[6].dosage}",
      I18n.l(bp_3.recorded_at.to_date),
      quarter_string(bp_3.recorded_at.to_date),
      bp_3.systolic,
      bp_3.diastolic,
      bp_3.facility.name,
      bp_3.facility.facility_type,
      bp_3.facility.district,
      bp_3.facility.state,
      bp_3_follow_up.facility.name,
      I18n.l(bp_3_follow_up.scheduled_date.to_date),
      bp_3_follow_up.follow_up_days,
      "No",
      old_prescription_drug.name,
      old_prescription_drug.dosage,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      I18n.l(blood_sugar.recorded_at.to_date),
      "#{blood_sugar.blood_sugar_value} mg/dL",
      "Fasting"
    ]
  end

  before do
    allow(patient).to receive(:high_risk?).and_return(true)
    allow(Rails.application.config.country).to receive(:[]).with(:patient_line_list_show_zone).and_return(true)
    blood_sugar.update!(encounter: bp_1.encounter)
    patient.medical_history.update!(hypertension: "no", diabetes: "yes")
    MaterializedPatientSummary.refresh
  end

  describe "#csv" do
    it "generates a CSV of patient records" do
      Timecop.freeze do
        timestamp = ["Report generated at:", Time.current]

        expect(subject.csv(Patient.all).to_s.strip).to eq((timestamp.to_csv + headers.to_csv + fields.to_csv).to_s.strip)
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
