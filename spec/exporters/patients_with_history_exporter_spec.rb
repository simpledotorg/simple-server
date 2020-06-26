require "rails_helper"

RSpec.describe PatientsWithHistoryExporter do
  include QuarterHelper

  let!(:now) { Time.current }

  let!(:patient) { create(:patient, status: "dead") }
  let!(:facility) { patient.registration_facility }
  let!(:user) { patient.registration_user }

  let!(:bp_1) { create(:blood_pressure, :with_encounter, :critical, recorded_at: 2.months.ago, facility: facility, patient: patient, user: user) }
  let!(:blood_sugar) { create(:blood_sugar, :fasting, :with_encounter, recorded_at: 2.months.ago, facility: facility, patient: patient, user: user) }
  let!(:bp_1_follow_up) { create(:appointment, :overdue, device_created_at: 2.months.ago, scheduled_date: 40.days.ago, creation_facility: facility, patient: patient, user: user) }

  let!(:bp_2) { create(:blood_pressure, :with_encounter, recorded_at: 3.months.ago, facility: facility, patient: patient, user: user) }
  let!(:old_blood_sugar) { create(:blood_sugar, :with_encounter, recorded_at: 3.months.ago, facility: facility, patient: patient, user: user) }
  let!(:bp_2_follow_up) { create(:appointment, device_created_at: 3.months.ago, scheduled_date: 2.months.ago, creation_facility: facility, patient: patient, user: user) }

  let!(:bp_3) { create(:blood_pressure, :with_encounter, recorded_at: 4.months.ago, facility: facility, patient: patient, user: user) }
  let!(:bp_3_follow_up) { create(:appointment, device_created_at: 4.month.ago, scheduled_date: 3.months.ago, creation_facility: facility, patient: patient, user: user) }

  let!(:prescription_drugs) do
    [
      *create_list(:prescription_drug,
        4,
        :protocol,
        device_created_at: 3.months.ago,
        facility: facility,
        patient: patient).sort_by(&:name),
      *create_list(:prescription_drug,
        3,
        device_created_at: 3.months.ago,
        facility: facility,
        patient: patient).sort_by(&:name)
    ]
  end

  let!(:timestamp) { ["Report generated at:", now] }
  let(:headers) do
    [
      "Registration Date",
      "Registration Quarter",
      "Patient died?",
      "Simple Patient ID",
      "BP Passport ID",
      "Patient Name",
      "Patient Age",
      "Patient Gender",
      "Patient Phone Number",
      "Patient Street Address",
      "Patient Village/Colony",
      "Patient District",
      "Patient Zone",
      "Patient State",
      "Registration Facility Name",
      "Registration Facility Type",
      "Registration Facility District",
      "Registration Facility State",
      "Risk Level",
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
      "BP 1 Medication Updated",
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
      "BP 2 Medication Updated",
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
      "BP 3 Medication Updated",
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
      I18n.l(patient.recorded_at),
      quarter_string(patient.recorded_at),
      "Died",
      patient.id,
      patient.latest_bp_passport&.shortcode,
      patient.full_name,
      patient.current_age,
      patient.gender.capitalize,
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
      "High",
      I18n.l(bp_1.recorded_at),
      quarter_string(bp_1.recorded_at),
      bp_1.systolic,
      bp_1.diastolic,
      bp_1.facility.name,
      bp_1.facility.facility_type,
      bp_1.facility.district,
      bp_1.facility.state,
      bp_1_follow_up.facility.name,
      bp_1_follow_up.scheduled_date,
      bp_1_follow_up.follow_up_days,
      "placeholder - BP 1 Medication Updated",
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
      I18n.l(bp_2.recorded_at),
      quarter_string(bp_2.recorded_at),
      bp_2.systolic,
      bp_2.diastolic,
      bp_2.facility.name,
      bp_2.facility.facility_type,
      bp_2.facility.district,
      bp_2.facility.state,
      bp_2_follow_up.facility.name,
      bp_2_follow_up.scheduled_date,
      bp_2_follow_up.follow_up_days,
      "placeholder - BP 2 Medication Updated",
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
      I18n.l(bp_3.recorded_at),
      quarter_string(bp_3.recorded_at),
      bp_3.systolic,
      bp_3.diastolic,
      bp_3.facility.name,
      bp_3.facility.facility_type,
      bp_3.facility.district,
      bp_3.facility.state,
      bp_3_follow_up.facility.name,
      bp_3_follow_up.scheduled_date,
      bp_3_follow_up.follow_up_days,
      "placeholder - BP 3 Medication Updated",
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      I18n.l(blood_sugar.recorded_at),
      "#{blood_sugar.blood_sugar_value} mg/dL",
      "Fasting"
    ]
  end

  before do
    allow(Rails.application.config.country).to receive(:[]).with(:patient_line_list_show_zone).and_return(true)
  end

  describe "#csv" do
    let(:patient_batch) { Patient.where(id: patient.id) }

    it "generates a CSV of patient records" do
      travel_to now do
        expect(subject.csv(Patient.all)).to eq(timestamp.to_csv + headers.to_csv + fields.to_csv)
      end
    end

    it "generates a blank CSV (only headers) if no patients exist" do
      travel_to now do
        expect(subject.csv(Patient.none)).to eq(timestamp.to_csv + headers.to_csv)
      end
    end

    it "uses fetches patients in batches" do
      expect_any_instance_of(facility.registered_patients.class).to receive(:in_batches).and_return([patient_batch])

      subject.csv(facility.registered_patients)
    end

    it "does not include the zone column if the country config is set to false" do
      allow(Rails.application.config.country).to receive(:[]).with(:patient_line_list_show_zone).and_return(false)

      expect(subject.csv_headers).not_to include("Patient #{Address.human_attribute_name :zone}")
      expect(subject.csv_fields(patient)).not_to include(patient.address.zone)
    end
  end
end
