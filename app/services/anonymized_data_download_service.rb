require 'csv'

class AnonymizedDataDownloadService
  DATA_ANONYMIZATION_COLLECTION_START_DATE = 12.months.ago

  UNAVAILABLE = 'Unavailable'.freeze

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
    district_facilities = district.facilities
    anonymize(district_data_map(district_facilities))
  end

  def anonymize_facility(facility)
    anonymize(facility_data_map(facility))
  end

  def anonymize(csv_data_map)
    combined_csv_data = {}

    csv_data_map.each do |file_name, data|
      combined_csv_data[file_name] = to_csv(data)
    end

    combined_csv_data
  end

  def facility_data_map(facility)
    appointments = appointment_data(facility)
    users_phone_numbers = facility.users.compact.map(&:phone_number).uniq

    {
      PATIENTS_FILE => patient_data(facility),
      BPS_FILE => bp_data(facility),
      MEDICINES_FILE => prescription_data(facility),
      APPOINTMENTS_FILE => appointments,
      SMS_REMINDERS_FILE => communication_data(appointments),
      PHONE_CALLS_FILE => phone_call_data(users_phone_numbers)
    }
  end

  def district_data_map(district_facilities)
    patients = []
    district_facilities.each { |fac| patients << patient_data(fac) }; patients.flatten!

    blood_pressures = []
    district_facilities.each { |fac| blood_pressures << bp_data(fac) }; blood_pressures.flatten!

    prescriptions = []
    district_facilities.each { |fac| prescriptions << prescription_data(fac) }; prescriptions.flatten!

    appointments = []
    district_facilities.each { |fac| appointments << appointment_data(fac) }; appointments.flatten!

    users_phone_numbers = district_facilities.flat_map(&:users).compact.map(&:phone_number).uniq

    {
      PATIENTS_FILE => patients,
      BPS_FILE => blood_pressures,
      MEDICINES_FILE => prescriptions,
      APPOINTMENTS_FILE => appointments,
      SMS_REMINDERS_FILE => communication_data(appointments),
      PHONE_CALLS_FILE => phone_call_data(users_phone_numbers),
    }
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
    appointments.flat_map(&:communications).select { |comm| comm.device_created_at >= DATA_ANONYMIZATION_COLLECTION_START_DATE }
  end

  def phone_call_data(users_phone_numbers)
    CallLog.all.select { |call| users_phone_numbers.include?(call.caller_phone_number && call.created_at >= DATA_ANONYMIZATION_COLLECTION_START_DATE) }
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
          values[h.to_sym] || UNAVAILABLE
        end
      end
    end
  end
end