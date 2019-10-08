require "rails_helper"

RSpec.describe PatientsExporter do
  let!(:facility) { create(:facility) }
  let!(:patient) { create(:patient, registration_facility: facility) }
  let!(:blood_pressure) { create(:blood_pressure, facility: facility, patient: patient) }
  let!(:appointment) { create(:appointment, :overdue, facility: facility, patient: patient) }

  let(:headers) do
    [
      "Simple Patient ID",
      "BP Passport ID",
      "Patient Name",
      "Patient Gender",
      "Patient Age",
      "Patient Village/Colony",
      "Patient District",
      "Patient State",
      "Patient Phone Number",
      "Registration Date",
      "Registration Facility Name",
      "Registration Facility Type",
      "Latest BP Systolic",
      "Latest BP Diastolic",
      "Latest BP Date",
      "Latest BP Facility Name",
      "Latest BP Facility Type",
      "Days Overdue",
      "Risk Level"
    ]
  end

  let(:fields) do
    [
      patient.id,
      patient.latest_bp_passport&.shortcode,
      patient.full_name,
      patient.gender.capitalize,
      patient.current_age,
      patient.address.village_or_colony,
      patient.address.district,
      patient.address.state,
      patient.phone_numbers.last&.number,
      I18n.l(patient.recorded_at),
      facility.name,
      facility.facility_type,
      blood_pressure.systolic,
      blood_pressure.diastolic,
      I18n.l(blood_pressure.recorded_at),
      blood_pressure.facility.name,
      blood_pressure.facility.facility_type,
      appointment.days_overdue,
      patient.risk_priority_label
    ]
  end

  describe "#csv" do
    it "generates a CSV of patient records" do
      expect(subject.csv([patient])).to eq(headers.to_csv + fields.to_csv)
    end

    it "generates a blank CSV (only headers) if no patients exist" do
      expect(subject.csv([])).to eq(headers.to_csv)
    end
  end
end

