require "csv"

module PatientsExporter
  extend QuarterHelper

  BATCH_SIZE = 20
  BLOOD_SUGAR_TYPES = {
    random: "Random",
    post_prandial: "Postprandial",
    fasting: "Fasting",
    hba1c: "HbA1c"
  }.with_indifferent_access.freeze

  def self.csv(patients)
    CSV.generate(headers: true) do |csv|
      csv << timestamp
      csv << csv_headers

      patients.in_batches(of: BATCH_SIZE).each do |batch|
        batch.includes(
          :registration_facility,
          :phone_numbers,
          :address,
          :medical_history,
          :current_prescription_drugs
        ).each do |patient|
          csv << csv_fields(patient)
        end
      end
    end
  end

  def self.timestamp
    [
      "Report generated at:",
      Time.current
    ]
  end

  def self.csv_headers
    [
      "Registration Date",
      "Registration Quarter",
      "Patient died?",
      "Patient Name",
      "Patient Age",
      "Patient Gender",
      "Patient Phone Number",
      "Patient Street Address",
      "Patient Village/Colony",
      "Patient District",
      (zone_column if Rails.application.config.country[:patient_line_list_show_zone]),
      "Patient State",
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
    ].compact
  end

  def self.csv_fields(patient)
    # We cannot rely on the ordered scopes on Patient (eg. latest_blood_pressures) to find most recent records because
    # the batching done here will invalidate any ordering on patients, as well as its associations.
    registration_facility = patient.registration_facility
    latest_bp = patient.blood_pressures.order(recorded_at: :desc).first
    latest_bp_facility = latest_bp&.facility
    latest_blood_sugar = patient.blood_sugars.order(recorded_at: :desc).first
    latest_appointment = patient.latest_scheduled_appointments.order(scheduled_date: :desc).first
    latest_bp_passport = patient.latest_bp_passports.order(device_created_at: :desc).first
    zone_column_index = csv_headers.index(zone_column)

    csv_fields = [
      patient.recorded_at.presence && I18n.l(patient.recorded_at),
      patient.recorded_at.presence && quarter_string(patient.recorded_at),
      ("Died" if patient.status == "dead"),
      patient.full_name,
      patient.current_age,
      patient.gender.capitalize,
      patient.phone_numbers.last&.number,
      patient.address.street_address,
      patient.address.village_or_colony,
      patient.address.district,
      patient.address.state,
      registration_facility&.name,
      registration_facility&.facility_type,
      registration_facility&.district,
      registration_facility&.state,
      patient.medical_history&.hypertension,
      patient.medical_history&.diabetes,
      latest_bp&.recorded_at.presence && I18n.l(latest_bp&.recorded_at),
      latest_bp&.systolic,
      latest_bp&.diastolic,
      latest_bp&.recorded_at.presence && quarter_string(latest_bp&.recorded_at),
      latest_bp_facility&.name,
      latest_bp_facility&.facility_type,
      latest_bp_facility&.district,
      latest_bp_facility&.state,
      latest_blood_sugar&.recorded_at.presence && I18n.l(latest_blood_sugar&.recorded_at),
      latest_blood_sugar&.to_s,
      blood_sugar_type(latest_blood_sugar),
      latest_appointment&.facility&.name,
      latest_appointment&.scheduled_date&.to_s(:rfc822),
      latest_appointment&.days_overdue,
      ("High" if patient.high_risk?),
      latest_bp_passport&.shortcode,
      patient.id,
      *medications_for(patient)
    ]

    csv_fields.insert(zone_column_index, patient.address.zone) if zone_column_index
    csv_fields
  end

  def self.medications_for(patient)
    patient.current_prescription_drugs.flat_map { |drug| [drug.name, drug.dosage] }
  end

  private_class_method

  def self.zone_column
    "Patient #{Address.human_attribute_name :zone}"
  end

  def self.blood_sugar_type(blood_sugar)
    return unless blood_sugar.present?

    BLOOD_SUGAR_TYPES[blood_sugar.blood_sugar_type]
  end
end
