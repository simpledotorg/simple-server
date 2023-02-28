require "csv"

class PatientsWithHistoryExporter
  include QuarterHelper

  # Since we are populating this export using a materialized view,
  # changing these values is not enough to add more fields to the export.
  # We also need to update MaterializedPatientSummary to include columns for
  # more blood pressures and blood sugars

  BLOOD_PRESSURES_TO_DISPLAY = 3
  BLOOD_SUGARS_TO_DISPLAY = 3

  BATCH_SIZE = 1000

  PATIENT_STATUS_DESCRIPTIONS = {
    active: "Active",
    migrated: "Transferred out",
    dead: "Died",
    ltfu: "Lost to follow-up"
  }.with_indifferent_access

  BLOOD_SUGAR_TYPES = {
    random: "Random",
    post_prandial: "Postprandial",
    fasting: "Fasting",
    hba1c: "HbA1c"
  }.with_indifferent_access.freeze

  attr_reader :display_blood_sugars

  def self.csv(*args)
    new.csv(*args)
  end

  def csv(patients, display_blood_sugars: true)
    @display_blood_sugars = display_blood_sugars
    summary = MaterializedPatientSummary.where(patient: patients)

    CSV.generate(headers: true) do |csv|
      csv << timestamp
      csv << measurement_headers
      csv << csv_headers

      summary.in_batches(of: BATCH_SIZE).each do |batch|
        batch.each do |patient_summary|
          csv << csv_fields(patient_summary)
        end
      end
    end
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
      "Days Overdue For Next Follow-up",
      (1..BLOOD_PRESSURES_TO_DISPLAY).map { |i| blood_pressure_headers(i) },
      display_blood_sugars ?
        (1..BLOOD_SUGARS_TO_DISPLAY).map { |i| blood_sugar_headers(i) } :
        ["Latest Blood Sugar Date",
          "Latest Blood Sugar Value",
          "Latest Blood Sugar Type"]

    ].compact.flatten
  end

  def measurement_headers
    [
      25.times.map { nil }, # Non-measurement related headers
      (1..BLOOD_PRESSURES_TO_DISPLAY).map { |i| ["Blood Pressure #{i}"] + (blood_pressure_headers(0).length - 1).times.map { nil } },
      (1..BLOOD_SUGARS_TO_DISPLAY).map { |i| ["Blood Sugar #{i}"] + (blood_sugar_headers(0).length - 1).times.map { nil } }
    ].flatten
  end

  def csv_fields(patient_summary)
    patient_details = [
      I18n.l(patient_summary.recorded_at.to_date),
      quarter_string(patient_summary.recorded_at),
      patient_summary.id,
      patient_summary.latest_bp_passport&.shortcode,
      patient_summary.full_name,
      patient_summary.current_age.to_i,
      patient_summary.gender.capitalize,
      status(patient_summary),
      patient_summary.latest_phone_number,
      patient_summary.street_address,
      patient_summary.village_or_colony,
      patient_summary.district,
      (patient_summary.zone if Rails.application.config.country[:patient_line_list_show_zone]),
      patient_summary.state
    ].compact

    facility_details = [
      patient_summary.assigned_facility_name,
      patient_summary.assigned_facility_type,
      patient_summary.assigned_facility_district,
      patient_summary.assigned_facility_state,
      patient_summary.registration_facility_name,
      patient_summary.registration_facility_type,
      patient_summary.registration_facility_district,
      patient_summary.registration_facility_state
    ]

    treatment_history = [
      patient_summary.hypertension,
      patient_summary.diabetes,
      patient_summary.days_overdue.to_i
    ]

    blood_pressures = (1..BLOOD_PRESSURES_TO_DISPLAY).map { |i| blood_pressure_fields(patient_summary, i) }.flatten

    blood_sugars = if display_blood_sugars
      (1..BLOOD_SUGARS_TO_DISPLAY).map { |i| blood_sugar_fields(patient_summary, i) }.flatten
    else
      [I18n.l(patient_summary.latest_blood_sugar_1_recorded_at.to_date),
        patient_summary.latest_blood_sugar_1_blood_sugar_value,
        patient_summary.latest_blood_sugar_1_blood_sugar_type]
    end

    [patient_details,
      facility_details,
      treatment_history,
      blood_pressures,
      blood_sugars].flatten
  end

  private

  def blood_pressure_headers(i)
    [
      "BP #{i} Date",
      "BP #{i} Quarter",
      "BP #{i} Systolic",
      "BP #{i} Diastolic",
      "BP #{i} Facility Name",
      "BP #{i} Facility Type",
      "BP #{i} Facility District",
      "BP #{i} Facility State",
      "BP #{i} Follow-up Facility",
      "BP #{i} Follow-up Date",
      "BP #{i} Follow up Days",
      "BP #{i} Medication Titrated",
      "BP #{i} Medication 1",
      "BP #{i} Dosage 1",
      "BP #{i} Medication 2",
      "BP #{i} Dosage 2",
      "BP #{i} Medication 3",
      "BP #{i} Dosage 3",
      "BP #{i} Medication 4",
      "BP #{i} Dosage 4",
      "BP #{i} Medication 5",
      "BP #{i} Dosage 5",
      "BP #{i} Other Medications"
    ]
  end

  def blood_sugar_headers(i)
    [
      "Blood sugar #{i} Date",
      "Blood sugar #{i} Quarter",
      "Blood sugar #{i} Type",
      "Blood sugar #{i} Value",
      "Blood sugar #{i} Facility Name",
      "Blood sugar #{i} Facility Type",
      "Blood sugar #{i} Facility District",
      "Blood sugar #{i} Facility State",
      "Blood sugar #{i} Follow-up Facility",
      "Blood sugar #{i} Follow-up Date",
      "Blood sugar #{i} Follow up Days"
    ]
  end

  def blood_pressure_fields(patient_summary, i)
    unless patient_summary.public_send("latest_blood_pressure_#{i}_id").present?
      return Array.new(23)
    end

    [I18n.l(patient_summary.public_send("latest_blood_pressure_#{i}_recorded_at").to_date),
      quarter_string(patient_summary.public_send("latest_blood_pressure_#{i}_recorded_at").to_date),
      patient_summary.public_send("latest_blood_pressure_#{i}_systolic"),
      patient_summary.public_send("latest_blood_pressure_#{i}_diastolic"),
      patient_summary.public_send("latest_blood_pressure_#{i}_facility_name"),
      patient_summary.public_send("latest_blood_pressure_#{i}_facility_type"),
      patient_summary.public_send("latest_blood_pressure_#{i}_district"),
      patient_summary.public_send("latest_blood_pressure_#{i}_state"),
      patient_summary.public_send("latest_blood_pressure_#{i}_follow_up_facility_name"),
      patient_summary.public_send("latest_blood_pressure_#{i}_follow_up_date") ? I18n.l(patient_summary.public_send("latest_blood_pressure_#{i}_follow_up_date")) : nil,
      patient_summary.public_send("latest_blood_pressure_#{i}_follow_up_days"),
      patient_summary.public_send("latest_blood_pressure_#{i}_medication_updated") ? "Yes" : "No",
      patient_summary.public_send("latest_blood_pressure_#{i}_prescription_drug_1_name"),
      patient_summary.public_send("latest_blood_pressure_#{i}_prescription_drug_1_dosage"),
      patient_summary.public_send("latest_blood_pressure_#{i}_prescription_drug_2_name"),
      patient_summary.public_send("latest_blood_pressure_#{i}_prescription_drug_2_dosage"),
      patient_summary.public_send("latest_blood_pressure_#{i}_prescription_drug_3_name"),
      patient_summary.public_send("latest_blood_pressure_#{i}_prescription_drug_3_dosage"),
      patient_summary.public_send("latest_blood_pressure_#{i}_prescription_drug_4_name"),
      patient_summary.public_send("latest_blood_pressure_#{i}_prescription_drug_4_dosage"),
      patient_summary.public_send("latest_blood_pressure_#{i}_prescription_drug_5_name"),
      patient_summary.public_send("latest_blood_pressure_#{i}_prescription_drug_5_dosage"),
      patient_summary.public_send("latest_blood_pressure_#{i}_other_prescription_drugs")]
  end

  def blood_sugar_fields(patient_summary, i)
    unless patient_summary.public_send("latest_blood_sugar_#{i}_id").present?
      return Array.new(11)
    end

    [I18n.l(patient_summary.public_send("latest_blood_sugar_#{i}_recorded_at").to_date),
      quarter_string(patient_summary.public_send("latest_blood_sugar_#{i}_recorded_at").to_date),
      patient_summary.public_send("latest_blood_sugar_#{i}_blood_sugar_type"),
      patient_summary.public_send("latest_blood_sugar_#{i}_blood_sugar_value"),
      patient_summary.public_send("latest_blood_sugar_#{i}_facility_name"),
      patient_summary.public_send("latest_blood_sugar_#{i}_facility_type"),
      patient_summary.public_send("latest_blood_sugar_#{i}_district"),
      patient_summary.public_send("latest_blood_sugar_#{i}_state"),
      patient_summary.public_send("latest_blood_sugar_#{i}_follow_up_facility_name"),
      patient_summary.public_send("latest_blood_sugar_#{i}_follow_up_date") ? I18n.l(patient_summary.public_send("latest_blood_sugar_#{i}_follow_up_date")) : nil,
      patient_summary.public_send("latest_blood_sugar_#{i}_follow_up_days")]
  end

  def zone_column
    "Patient #{Address.human_attribute_name :zone}"
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
