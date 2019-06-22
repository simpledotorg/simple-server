require 'csv'

class AnonymizedDataDownloadService
  DATA_ANONYMIZATION_COLLECTION_START_DATE = 12.months.ago

  PATIENTS_FILE = 'patients.csv'.freeze
  BPS_FILE = 'blood_pressures.csv'.freeze
  MEDICINES_FILE = 'medicines.csv'.freeze
  APPOINTMENTS_FILE = 'appointments.csv'.freeze
  SMS_REMINDERS_FILE = 'sms_reminders.csv'.freeze
  PHONE_CALLS_FILE = 'phone_calls.csv'.freeze

  def run_for_district(recipient_name, recipient_email, district_name, organization_id)
    organization_district = OrganizationDistrict.new(district_name, Organization.find(organization_id))
    anonymized_data = anonymize_district(organization_district)

    names_of_facilities = organization_district.facilities.flat_map(&:name).sort

    AnonymizedDataDownloadMailer
      .with(recipient_name: recipient_name,
            recipient_email: recipient_email,
            anonymized_data: anonymized_data,
            resource: { district_name: district_name,
                        facilities: names_of_facilities })
      .mail_anonymized_data
      .deliver_later
  end

  def run_for_facility(recipient_name, recipient_email, facility_id)
    facility = Facility.find(facility_id)
    anonymized_data = anonymize_facility(facility)

    AnonymizedDataDownloadMailer
      .with(recipient_name: recipient_name,
            recipient_email: recipient_email,
            anonymized_data: anonymized_data,
            resource: { facility_name: facility.name,
                        facilities: [facility.name] })
      .mail_anonymized_data
      .deliver_later
  end

  private

  def anonymize_district(district)
    facilities = district.facilities

    csv_data = {}

    patients = []
    facilities.each do |fac|
      patients << patient_data(fac)
    end

    patients.flatten!
    csv_data[PATIENTS_FILE] = to_csv(patients)

    blood_pressures = []
    facilities.each do |fac|
      blood_pressures << patient_data(fac)
    end

    blood_pressures.flatten!
    blood_pressures_csv_data = to_csv(blood_pressures)
    csv_data[BPS_FILE] = blood_pressures_csv_data if blood_pressures_csv_data.present?

    prescriptions = []
    facilities.each do |fac|
      prescriptions << prescription_data(fac)
    end

    prescriptions.flatten!
    prescriptions_csv_data = to_csv(prescriptions)
    csv_data[MEDICINES_FILE] = prescriptions_csv_data if prescriptions_csv_data.present?

    appointments = []

    facilities.each do |fac|
      appointments << appointment_data(fac)
    end

    appointments.flatten!
    appointments_csv_data = to_csv(appointments)
    csv_data[APPOINTMENTS_FILE] = appointments_csv_data if appointments_csv_data.present?

    communications = communication_data(appointments)
    communications_csv_data = to_csv(communications)
    csv_data[SMS_REMINDERS_FILE] = communications_csv_data if communications_csv_data.present?

    all_bp_users_phone_numbers = facilities.flat_map(&:users).compact.map(&:phone_number).uniq
    phone_calls = phone_call_data(all_bp_users_phone_numbers)
    phone_calls_csv_data = to_csv(phone_calls)
    csv_data[PHONE_CALLS_FILE] = phone_calls_csv_data if phone_calls_csv_data.present?

    csv_data
  end

  def anonymize_facility(facility)
    csv_data = {}

    patients = patient_data(facility)
    csv_data[PATIENTS_FILE] = to_csv(patients)

    blood_pressures = bp_data(facility)
    blood_pressures_csv_data = to_csv(blood_pressures)
    csv_data[BPS_FILE] = blood_pressures_csv_data if blood_pressures_csv_data.present?

    prescriptions = prescription_data(facility)
    prescriptions_csv_data = to_csv(prescriptions)
    csv_data[MEDICINES_FILE] = prescriptions_csv_data if prescriptions_csv_data.present?

    appointments = appointment_data(facility)
    appointments_csv_data = to_csv(appointments)
    csv_data[APPOINTMENTS_FILE] = appointments_csv_data if appointments_csv_data.present?

    communications = communication_data(appointments)
    communications_csv_data = to_csv(communications)
    csv_data[SMS_REMINDERS_FILE] = communications_csv_data if communications_csv_data.present?

    all_bp_users_phone_numbers = facility.users.compact.map(&:phone_number).uniq
    phone_calls = phone_call_data(all_bp_users_phone_numbers)
    phone_calls_csv_data = to_csv(phone_calls)
    csv_data[PHONE_CALLS_FILE] = phone_calls_csv_data if phone_calls_csv_data.present?

    csv_data
  end

  def patient_data(facility)
    facility.patients.select { |p| p.device_created_at >= DATA_ANONYMIZATION_COLLECTION_START_DATE }
  end

  def bp_data(facility)
    facility.blood_pressures.select { |bp| bp.device_created_at >= DATA_ANONYMIZATION_COLLECTION_START_DATE }
  end

  def prescription_data(facility)
    facility.prescription_drugs.select { |pd| pd.device_created_at >= DATA_ANONYMIZATION_COLLECTION_START_DATE }
  end

  def appointment_data(facility)
    facility.appointments.select { |app| app.device_created_at >= DATA_ANONYMIZATION_COLLECTION_START_DATE }
  end

  def communication_data(appointments)
    appointments.flat_map(&:communications).select { |comm| comm.device_created_dat >= DATA_ANONYMIZATION_COLLECTION_START_DATE }
  end

  def phone_call_data(all_bp_users_phone_numbers)
    CallLog.all.select { |call| all_bp_users_phone_numbers.include?(call.caller_phone_number && call.created_at >= DATA_ANONYMIZATION_COLLECTION_START_DATE) }
  end

  def to_csv(resources)
    return unless resources.present?

    klass = resources.first.class
    headers = klass::ANONYMIZED_DATA_FIELDS

    CSV.generate(headers: true) do |csv|
      csv << headers.map(&:titleize)

      resources.map do |r|
        values = r.anonymized_data
        csv << headers.map do |h|
          values[h.to_sym]
        end
      end
    end
  end
end