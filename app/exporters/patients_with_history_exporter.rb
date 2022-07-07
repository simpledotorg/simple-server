require "csv"

class PatientsWithHistoryExporter
  include QuarterHelper

  DEFAULT_DISPLAY_BLOOD_PRESSURES = 3
  DEFAULT_DISPLAY_MEDICATION_COLUMNS = 5
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
    patients = *args
    new.csv(patients)
  end

  def csv(patients, display_blood_pressures: DEFAULT_DISPLAY_BLOOD_PRESSURES, display_medication_columns: DEFAULT_DISPLAY_MEDICATION_COLUMNS)
    @display_blood_pressures = display_blood_pressures
    @display_medication_columns = display_medication_columns
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
        :latest_bp_passport,
        {appointments: :facility},
        {latest_blood_pressures: :facility}
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
      "Risk Level",
      "Days Overdue For Next Follow-up",
      (1..display_blood_pressures).map do |i|
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
      end,
      "Latest Blood Sugar Date",
      "Latest Blood Sugar Value",
      "Latest Blood Sugar Type"
    ].flatten.compact
  end

  def csv_fields(patient_summary)
    latest_bps = patient_summary
      .latest_blood_pressures
      .first(display_blood_pressures + 1)

    all_medications = fetch_medication_history(patient_summary, latest_bps.map(&:recorded_at))
    zone_column_index = csv_headers.index(zone_column)

    patient_appointments = patient_summary
      .appointments
      .sort_by(&:device_created_at)

    csv_fields = [
      registration_date(patient_summary),
      registration_quarter(patient_summary),
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
      ("High" if patient_summary.risk_level > 0),
      patient_summary.days_overdue.to_i,
      (1..display_blood_pressures).map do |i|
        bp = latest_bps[i - 1]
        previous_bp = latest_bps[i]
        appointment = appointment_created_on(patient_appointments, bp&.recorded_at)

        [bp&.recorded_at.presence && I18n.l(bp&.recorded_at&.to_date),
          bp&.recorded_at.presence && quarter_string(bp&.recorded_at&.to_date),
          bp&.systolic,
          bp&.diastolic,
          bp&.facility&.name,
          bp&.facility&.facility_type,
          bp&.facility&.district,
          bp&.facility&.state,
          appointment&.facility&.name,
          appointment&.scheduled_date.presence && I18n.l(appointment&.scheduled_date&.to_date),
          appointment&.follow_up_days,
          medication_updated?(all_medications, bp&.recorded_at, previous_bp&.recorded_at),
          *formatted_medications(all_medications, bp&.recorded_at)]
      end,
      latest_blood_sugar_date(patient_summary),
      patient_summary.latest_blood_sugar.to_s,
      latest_blood_sugar_type(patient_summary)
    ].flatten

    csv_fields.insert(zone_column_index, patient_summary.block) if zone_column_index
    csv_fields
  end

  private

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

  def display_blood_pressures
    @display_blood_pressures || DEFAULT_DISPLAY_BLOOD_PRESSURES
  end

  def display_medication_columns
    @display_medication_columns || DEFAULT_DISPLAY_MEDICATION_COLUMNS
  end

  def appointment_created_on(appointments, date)
    date && appointments.find { |a| date.all_day.cover?(a.device_created_at) }
  end

  def fetch_medication_history(patient_summary, dates)
    dates.each_with_object({}) { |date, cache|
      cache[date] =
        if date
          patient_summary.prescribed_drugs(date: date).order(is_protocol_drug: :desc, name: :asc).load
        else
          PrescriptionDrug.none
        end
    }
  end

  def medication_updated?(all_medications, date, previous_date)
    medications_on(all_medications, date) == medications_on(all_medications, previous_date) ? "No" : "Yes"
  end

  def formatted_medications(all_medications, date)
    medications = medications_on(all_medications, date)

    initial_medications =
      (0...display_medication_columns).flat_map { |i| [medications[i]&.name, medications[i]&.dosage] }

    other_medications =
      medications[display_medication_columns..medications.length]
        &.map { |medication| "#{medication.name}-#{medication.dosage}" }
        &.join(", ")

    initial_medications << other_medications
  end

  def medications_on(all_medications, date)
    if date
      all_medications[date]
    else
      PrescriptionDrug.none
    end
  end
end
