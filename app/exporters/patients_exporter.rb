require 'csv'

module PatientsExporter
  extend QuarterHelper

  BATCH_SIZE = 1000

  def self.csv(patients)
    CSV.generate(headers: true) do |csv|
      csv << csv_headers

      patients.in_batches(of: BATCH_SIZE).each do |batch|
        batch.each do |patient|
          csv << csv_fields(patient)
        end
      end
    end
  end

  def self.csv_headers
    [
      "Registration Date",
      "Registration Quarter",
      "Patient Name",
      "Patient Age",
      "Patient Gender",
      "Patient Phone Number",
      "Patient Village/Colony",
      "Patient District",
      "Patient State",
      "Registration Facility Name",
      "Registration Facility Type",
      "Registration Facility District",
      "Registration Facility State",
      "Latest BP Systolic",
      "Latest BP Diastolic",
      "Latest BP Date",
      "Latest BP Quarter",
      "Latest BP Facility Name",
      "Latest BP Facility Type",
      "Latest BP Facility District",
      "Latest BP Facility State",
      "Days Overdue",
      "Risk Level",
      "BP Passport ID",
      "Simple Patient ID"
    ]
  end

  def self.csv_fields(patient)
    registration_facility = patient.registration_facility
    latest_bp = patient.latest_blood_pressure
    latest_bp_facility = latest_bp&.facility

    [
      patient.recorded_at.presence && I18n.l(patient.recorded_at),
      patient.recorded_at.presence && quarter_string(patient.recorded_at),
      patient.full_name,
      patient.current_age,
      patient.gender.capitalize,
      patient.phone_numbers.last&.number,
      patient.address.village_or_colony,
      patient.address.district,
      patient.address.state,
      registration_facility&.name,
      registration_facility&.facility_type,
      registration_facility&.district,
      registration_facility&.state,
      latest_bp&.systolic,
      latest_bp&.diastolic,
      latest_bp&.recorded_at.presence && I18n.l(latest_bp&.recorded_at),
      latest_bp&.recorded_at.presence && quarter_string(latest_bp&.recorded_at),
      latest_bp_facility&.name,
      latest_bp_facility&.facility_type,
      latest_bp_facility&.district,
      latest_bp_facility&.state,
      patient.latest_scheduled_appointment&.days_overdue,
      patient.risk_priority_label,
      patient.latest_bp_passport&.shortcode,
      patient.id
    ]
  end
end
