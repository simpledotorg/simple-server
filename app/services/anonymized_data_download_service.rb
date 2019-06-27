require 'csv'

module AnonymizedData
  class DistrictData
    attr_reader :district_facilities

    def initialize(district)
      @district_facilities = district.facilities
    end

    def raw_data
      {
        AnonymizedData::Constants::PATIENTS_FILE => district_facilities.map { |fac| FacilityData.new(fac).patient_data }.flatten,
        AnonymizedData::Constants::BPS_FILE => district_facilities.map { |fac| FacilityData.new(fac).bp_data }.flatten,
        AnonymizedData::Constants::MEDICINES_FILE => district_facilities.map { |fac| FacilityData.new(fac).prescription_data }.flatten,
        AnonymizedData::Constants::APPOINTMENTS_FILE => appointments,
        AnonymizedData::Constants::SMS_REMINDERS_FILE => communication_data(appointments),
        AnonymizedData::Constants::PHONE_CALLS_FILE => phone_call_data(users_phone_numbers),
      }
    end

    def communication_data(appointments)
      appointments.flat_map(&:communications).select { |comm| comm.device_created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE }
    end

    def phone_call_data(users_phone_numbers)
      CallLog.all.select { |call| users_phone_numbers.include?(call.caller_phone_number && call.created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE) }
    end

    def users_phone_numbers
      district_facilities.flat_map(&:users).compact.map(&:phone_number).uniq
    end

    def appointments
      district_facilities.map { |fac| FacilityData.new(fac).appointment_data }.flatten
    end
  end

  class FacilityData
    attr_reader :facility, :appointments

    def initialize(facility)
      @facility = facility
      @appointments = appointment_data
    end

    def raw_data
      {
        AnonymizedData::Constants::PATIENTS_FILE => patient_data,
        AnonymizedData::Constants::BPS_FILE => bp_data,
        AnonymizedData::Constants::MEDICINES_FILE => prescription_data,
        AnonymizedData::Constants::APPOINTMENTS_FILE => appointments,
        AnonymizedData::Constants::SMS_REMINDERS_FILE => communication_data(appointments),
        AnonymizedData::Constants::PHONE_CALLS_FILE => phone_call_data(users_phone_numbers)
      }
    end

    def patient_data
      facility.patients.select { |p| p.device_created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE }
    end

    def bp_data
      facility.blood_pressures.select { |bp| bp.device_created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE }
    end

    def prescription_data
      facility.prescription_drugs.select { |pd| pd.device_created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE }
    end

    def appointment_data
      facility.appointments.select { |app| app.device_created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE }
    end

    def communication_data(appointments)
      appointments.flat_map(&:communications).select { |comm| comm.device_created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE }
    end

    def phone_call_data(users_phone_numbers)
      CallLog.all.select { |call| users_phone_numbers.include?(call.caller_phone_number && call.created_at >= AnonymizedData::Constants::ANONYMIZATION_START_DATE) }
    end

    def users_phone_numbers
      facility.users.compact.map(&:phone_number).uniq
    end
  end

  module Constants
    ANONYMIZATION_START_DATE = 12.months.ago
    UNAVAILABLE = 'Unavailable'.freeze
    PATIENTS_FILE = 'patients.csv'.freeze
    BPS_FILE = 'blood_pressures.csv'.freeze
    MEDICINES_FILE = 'medicines.csv'.freeze
    APPOINTMENTS_FILE = 'appointments.csv'.freeze
    SMS_REMINDERS_FILE = 'sms_reminders.csv'.freeze
    PHONE_CALLS_FILE = 'phone_calls.csv'.freeze
  end
end

class AnonymizedDataDownloadService
  def run_for_district(recipient_name, recipient_email, district_name, organization_id)
    organization_district = OrganizationDistrict.new(district_name, Organization.find(organization_id))
    names_of_facilities = organization_district.facilities.flat_map(&:name).sort
    send_email(recipient_name, recipient_email, anonymize(AnonymizedData::DistrictData.new(organization_district).raw_data), { district_name: district_name,
                                                                                                                               facilities: names_of_facilities })
  end

  def run_for_facility(recipient_name, recipient_email, facility_id)
    facility = Facility.find(facility_id)
    send_email(recipient_name, recipient_email, anonymize(AnonymizedData::FacilityData.new(facility).raw_data), { facility_name: facility.name,
                                                                                                                  facilities: [facility.name] })
  end

  private

  def send_email(recipient_name, recipient_email, anonymized_data, resource)
    AnonymizedDataDownloadMailer
      .with(recipient_name: recipient_name,
            recipient_email: recipient_email,
            anonymized_data: anonymized_data,
            resource: resource)
      .mail_anonymized_data
      .deliver_later
  end

  def anonymize(csv_data_map)
    combined_csv_data = {}

    csv_data_map.each do |file_name, data|
      combined_csv_data[file_name] = to_csv(data)
    end

    combined_csv_data
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
          values[h.to_sym] || AnonymizedData::Constants::UNAVAILABLE
        end
      end
    end
  end
end