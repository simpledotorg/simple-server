# frozen_string_literal: true

class PatientsExporter
  require "csv"
  include QuarterHelper

  BATCH_SIZE = 1000
  PATIENT_STATUS_DESCRIPTIONS = {active: "Active",
                                 migrated: "Transferred out",
                                 dead: "Died",
                                 ltfu: "Lost to follow-up"}.with_indifferent_access

  BLOOD_SUGAR_TYPES = {
    random: "Random",
    post_prandial: "Postprandial",
    fasting: "Fasting",
    hba1c: "HbA1c"
  }.with_indifferent_access.freeze

  def self.csv(*args)
    new.csv(*args)
  end

  def csv(patients)
    summary = MaterializedPatientSummary.where(patient: patients)

    CSV.generate(headers: true) do |csv|
      csv << timestamp
      csv << csv_headers

      summary.in_batches(of: BATCH_SIZE).each do |batch|
        load_batch(batch).each do |patient_summary|
          csv << csv_fields(patient_summary)
        end
      end
    end
  end

  def load_batch(batch)
    batch
      .includes(
        :current_prescription_drugs,
        :latest_blood_sugar,
        :latest_bp_passport
      )
  end

  def timestamp
    [
      "Report generated at:",
      Time.current
    ]
  end

  def csv_headers
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
      (zone_column if Rails.application.config.country[:patient_line_list_show_zone]),
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
    ].compact
  end

  def csv_fields(patient_summary)
    zone_column_index = csv_headers.index(zone_column)

    csv_fields = [
      registration_date(patient_summary),
      registration_quarter(patient_summary),
      patient_summary.full_name,
      patient_summary.current_age.to_i,
      patient_summary.gender.capitalize,
      status(patient_summary),
      patient_summary.latest_phone_number,
      patient_summary.street_address,
      patient_summary.village_or_colony,
      patient_summary.district,
      patient_summary.state,
      patient_summary.assigned_facility_name,
      patient_summary.assigned_facility_type,
      patient_summary.assigned_facility_district,
      patient_summary.assigned_facility_state,
      patient_summary.registration_facility_name,
      patient_summary.registration_facility_type,
      patient_summary.registration_district,
      patient_summary.registration_state,
      patient_summary.hypertension,
      patient_summary.diabetes,
      latest_bp_date(patient_summary),
      patient_summary.latest_blood_pressure_systolic,
      patient_summary.latest_blood_pressure_diastolic,
      latest_bp_quarter(patient_summary),
      patient_summary.latest_blood_pressure_facility_name,
      patient_summary.latest_blood_pressure_facility_type,
      patient_summary.latest_blood_pressure_district,
      patient_summary.latest_blood_pressure_state,
      latest_blood_sugar_date(patient_summary),
      patient_summary.latest_blood_sugar.to_s,
      latest_blood_sugar_type(patient_summary),
      patient_summary.next_scheduled_appointment_facility_name,
      patient_summary.next_scheduled_appointment_scheduled_date&.to_s(:rfc822),
      patient_summary.days_overdue.to_i,
      ("High" if patient_summary.risk_level > 0),
      patient_summary.latest_bp_passport&.shortcode,
      patient_summary.id,
      *medications_for(patient_summary)
    ]

    csv_fields.insert(zone_column_index, patient_summary.block) if zone_column_index
    csv_fields
  end

  private

  def medications_for(patient_summary)
    patient_summary.current_prescription_drugs.flat_map { |drug| [drug.name, drug.dosage] }
  end

  def zone_column
    "Patient #{Address.human_attribute_name :zone}"
  end

  def registration_date(patient_summary)
    patient_summary.recorded_at.presence &&
      I18n.l(patient_summary.recorded_at.to_date)
  end

  def registration_quarter(patient_summary)
    patient_summary.recorded_at.presence &&
      quarter_string(patient_summary.recorded_at)
  end

  def latest_bp_date(patient_summary)
    patient_summary.latest_blood_pressure_recorded_at.presence &&
      I18n.l(patient_summary.latest_blood_pressure_recorded_at.to_date)
  end

  def latest_bp_quarter(patient_summary)
    patient_summary.latest_blood_pressure_recorded_at.presence &&
      quarter_string(patient_summary.latest_blood_pressure_recorded_at)
  end

  def latest_blood_sugar_date(patient_summary)
    patient_summary.latest_blood_sugar_recorded_at.presence &&
      I18n.l(patient_summary.latest_blood_sugar_recorded_at.to_date)
  end

  def latest_blood_sugar_type(patient_summary)
    patient_summary.latest_blood_sugar_type.presence &&
      BLOOD_SUGAR_TYPES[patient_summary.latest_blood_sugar_type]
  end

  def status(patient_summary)
    patient_status = if patient_summary.ltfu?
      :ltfu
    else
      patient_summary.status
    end

    PATIENT_STATUS_DESCRIPTIONS[patient_status]
  end
end
