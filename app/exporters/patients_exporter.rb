require 'csv'

module PatientsExporter
  extend QuarterHelper

  BATCH_SIZE = 1000

  BLOOD_SUGAR_UNITS = {
    random: "mg/dL",
    post_prandial: "mg/dL",
    fasting: "mg/dL",
    hba1c: "%",
  }.with_indifferent_access.freeze

  BLOOD_SUGAR_TYPES = {
    random: "Random",
    post_prandial: "Postprandial",
    fasting: "Fasting",
    hba1c: "HbA1c",
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
          :current_prescription_drugs,
          :latest_bp_passports,
          { latest_scheduled_appointments: :facility },
          { latest_blood_pressures: [:facility, {encounter: :blood_sugars}] },
          :latest_blood_sugars
        ).each do |patient|
          csv << csv_fields(patient)
        end
      end
    end
  end

  def self.timestamp
    [
      'Report generated at:',
      Time.current
    ]
  end

  def self.csv_headers
    [
      'Registration Date',
      'Registration Quarter',
      'Patient died?',
      'Patient Name',
      'Patient Age',
      'Patient Gender',
      'Patient Phone Number',
      'Patient Street Address',
      'Patient Village/Colony',
      'Patient District',
      (zone_column if Rails.application.config.country[:patient_line_list_show_zone]),
      'Patient State',
      'Registration Facility Name',
      'Registration Facility Type',
      'Registration Facility District',
      'Registration Facility State',
      'Latest Visit Date',
      'Latest Visit Systolic BP',
      'Latest Visit Diastolic BP',
      'Latest Visit Blood Sugar Value',
      'Latest Visit Blood Sugar Type',
      'Latest Visit Quarter',
      'Latest Visit Facility Name',
      'Latest Visit Facility Type',
      'Latest Visit Facility District',
      'Latest Visit Facility State',
      'Follow-up Facility',
      'Follow-up Date',
      'Days Overdue',
      'Risk Level',
      'BP Passport ID',
      'Simple Patient ID',
      'Medication 1',
      'Dosage 1',
      'Medication 2',
      'Dosage 2',
      'Medication 3',
      'Dosage 3',
      'Medication 4',
      'Dosage 4',
      'Medication 5',
      'Dosage 5'
    ].compact
  end

  def self.csv_fields(patient)
    registration_facility = patient.registration_facility
    latest_bp = patient.latest_blood_pressures.first
    latest_bp_facility = latest_bp&.facility
    latest_blood_sugar = latest_bp&.encounter&.blood_sugars&.max_by(&:recorded_at)
    latest_appointment = patient.latest_scheduled_appointments.first
    latest_bp_passport = patient.latest_bp_passports.first
    zone_column_index = csv_headers.index(zone_column)

    csv_fields = [
      patient.recorded_at.presence && I18n.l(patient.recorded_at),
      patient.recorded_at.presence && quarter_string(patient.recorded_at),
      ('Died' if patient.status == 'dead'),
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
      latest_bp&.recorded_at.presence && I18n.l(latest_bp&.recorded_at),
      latest_bp&.systolic,
      latest_bp&.diastolic,
      blood_sugar_value_with_unit(latest_blood_sugar),
      blood_sugar_type(latest_blood_sugar),
      latest_bp&.recorded_at.presence && quarter_string(latest_bp&.recorded_at),
      latest_bp_facility&.name,
      latest_bp_facility&.facility_type,
      latest_bp_facility&.district,
      latest_bp_facility&.state,
      latest_appointment&.facility&.name,
      latest_appointment&.scheduled_date&.to_s(:rfc822),
      latest_appointment&.days_overdue,
      ('High' if patient.high_risk?),
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

  private

  def self.zone_column
    "Patient #{Address.human_attribute_name :zone}"
  end

  def self.blood_sugar_value_with_unit(blood_sugar)
    return unless blood_sugar.present?

    "#{blood_sugar.blood_sugar_value} #{BLOOD_SUGAR_UNITS[blood_sugar.blood_sugar_type]}"
  end

  def self.blood_sugar_type(blood_sugar)
    return unless blood_sugar.present?

    BLOOD_SUGAR_TYPES[blood_sugar.blood_sugar_type]
  end
end
