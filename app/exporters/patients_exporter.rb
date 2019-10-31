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

  private

  def self.csv_headers
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
      "Registration Quarter",
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
      "Risk Level"
    ]
  end

  def self.csv_fields(patient)
    registration_facility = patient.registration_facility
    latest_bp = patient.latest_blood_pressure
    latest_bp_facility = latest_bp&.facility

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
      patient.recorded_at.presence && I18n.l(patient.recorded_at),
      patient.recorded_at.presence && quarter_string(patient.recorded_at),
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
      patient.risk_priority_label
    ]
  end
end
