require "rails_helper"

RSpec.describe PatientExporter do
  let(:facility) { create(:facility) }
  let(:patient) { create(:patient, registration_facility: facility) }
  let(:blood_pressure) { create(:blood_pressure, facility: facility, patient: patient) }
  let(:appointment) { create(:appointment, :overdue, facility: facility, patient: patient) }

  describe "#csv" do
    it "generates a CSV of patient records" do
      headers = [
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

      fields = [
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

      expect(PatientExporter.csv([patient])).to eq(headers.to_csv + fields.to_csv)
    end
  end
end

