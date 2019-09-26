require 'csv'

module PatientExporter
  def self.csv(patients)
    CSV.generate(headers: true) do |csv|
      csv << csv_headers

      patients.each do |patient|
        csv << csv_fields(patient)
      end
    end
  end

  private

  def self.csv_headers
    [
      "Simple Patient ID",
      "BP Passport ID",
      "Patient Name",
      "Patient Gender",
      "Patient Age",
      "Patient Date of Birth",
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

  def self.csv_fields(patient)
    [
      patient.id,
      patient.latest_bp_passport,
      patient.full_name,
      patient.gender.capitalize,
      patient.current_age,
      patient.date_of_birth,
      patient.address.village_or_colony,
      patient.address.district,
      patient.address.state,
      patient.phone_numbers.last&.number,
      patient.registration_date,
      patient.registration_facility&.name,
      patient.registration_facility&.facility_type,
      patient.latest_blood_pressure&.systolic,
      patient.latest_blood_pressure&.diastolic,
      I18n.l(patient.latest_blood_pressure&.recorded_at),
      patient.latest_blood_pressure.facility.name,
      patient.latest_blood_pressure.facility.facility_type,
      patient.latest_scheduled_appointment&.days_overdue,
      patient.risk_priority_label
    ]
  end
end
