require "csv"

module PatientsWithHistoryExporter
  extend QuarterHelper

  BATCH_SIZE = 20
  BLOOD_SUGAR_TYPES = {
    random: "Random",
    post_prandial: "Postprandial",
    fasting: "Fasting",
    hba1c: "HbA1c"
  }.with_indifferent_access.freeze
  DISPLAY_BLOOD_PRESSURES = 3
  DISPLAY_MEDICATION_COLUMNS = 5

  def self.csv(patients)
    CSV.generate(headers: true) do |csv|
      csv << timestamp
      csv << csv_headers

      patients.in_batches(of: BATCH_SIZE).each do |batch|
        batch.includes(
          :registration_facility,
          :phone_numbers,
          :address
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
    ["Registration Date",
      "Registration Quarter",
      "Patient died?",
      "Simple Patient ID",
      "BP Passport ID",
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
      "Risk Level",
      "Days Overdue For Next Follow-up",
      (1..DISPLAY_BLOOD_PRESSURES).map do |i|
        ["BP #{i} Date",
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
          "BP #{i} Medication Updated",
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
          "BP #{i} Other Medications"]
      end,
      "Latest Blood Sugar Date",
      "Latest Blood Sugar Value",
      "Latest Blood Sugar Type"].flatten.compact
  end

  def self.csv_fields(patient)
    registration_facility = patient.registration_facility
    latest_bps = patient.latest_blood_pressures.first(DISPLAY_BLOOD_PRESSURES + 1)
    latest_blood_sugar = patient.latest_blood_sugar
    latest_appointment = patient.latest_scheduled_appointment
    latest_bp_passport = patient.latest_bp_passport
    fetch_medication_history(patient, latest_bps.map(&:recorded_at))
    zone_column_index = csv_headers.index(zone_column)

    csv_fields = [
      patient.recorded_at.presence && I18n.l(patient.recorded_at),
      patient.recorded_at.presence && quarter_string(patient.recorded_at),
      ("Died" if patient.status == "dead"),
      patient.id,
      latest_bp_passport&.shortcode,
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
      ("High" if patient.high_risk?),
      latest_appointment&.days_overdue,
      (1..DISPLAY_BLOOD_PRESSURES).map do |i|
        bp = latest_bps[i - 1]
        previous_bp = latest_bps[i]
        appointment = appointment_created_on(patient, bp&.recorded_at)

        [bp&.recorded_at.presence && I18n.l(bp&.recorded_at),
          bp&.recorded_at.presence && quarter_string(bp&.recorded_at),
          bp&.systolic,
          bp&.diastolic,
          bp&.facility&.name,
          bp&.facility&.facility_type,
          bp&.facility&.district,
          bp&.facility&.state,
          appointment&.facility&.name,
          appointment&.scheduled_date,
          appointment&.follow_up_days,
          medication_updated?(bp&.recorded_at, previous_bp&.recorded_at),
          *formatted_medications(bp&.recorded_at)]
      end,
      latest_blood_sugar&.recorded_at.presence && I18n.l(latest_blood_sugar&.recorded_at),
      latest_blood_sugar&.to_s,
      blood_sugar_type(latest_blood_sugar)
    ].flatten

    csv_fields.insert(zone_column_index, patient.address.zone) if zone_column_index
    csv_fields
  end

  class << self
    private

    def zone_column
      "Patient #{Address.human_attribute_name :zone}"
    end

    def appointment_created_on(patient, date)
      patient.appointments
        .where(device_created_at: date&.all_day)
        .order(device_created_at: :asc)
        .first
    end

    def fetch_medication_history(patient, dates)
      @medications = dates.each_with_object({}) { |date, cache|
        cache[date] = date ? patient.prescribed_drugs(date: date) : PrescriptionDrug.none
      }
    end

    def medications(date)
      date ? @medications[date] : PrescriptionDrug.none
    end

    def medication_updated?(date, previous_date)
      current_medications = medications(date)
      previous_medications = medications(previous_date)

      current_medications == previous_medications ? "No" : "Yes"
    end

    def formatted_medications(date)
      medications = medications(date)
      sorted_medications = medications.order(is_protocol_drug: :desc, name: :asc)
      other_medications = sorted_medications[DISPLAY_MEDICATION_COLUMNS..medications.length]
                            &.map { |medication| "#{medication.name}-#{medication.dosage}" }
                            &.join(", ")

      (0...DISPLAY_MEDICATION_COLUMNS).flat_map { |i|
        [sorted_medications[i]&.name, sorted_medications[i]&.dosage]
      } << other_medications
    end

    def blood_sugar_type(blood_sugar)
      return unless blood_sugar.present?

      BLOOD_SUGAR_TYPES[blood_sugar.blood_sugar_type]
    end
  end
end
