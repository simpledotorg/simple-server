require 'csv'

class AnonymizedDataDownloadService
  def initialize(recipient_name, recipient_email, recipient_role, entity_map, entity_type)
    @recipient_name = recipient_name
    @recipient_email = recipient_email
    @recipient_role = recipient_role
    @entity_map = entity_map
    @entity_type = entity_type
  end

  def execute
    begin
      anonymized_data = anonymize_data

      AnonymizedDataDownloadMailer
        .with(recipient_name: @recipient_name,
              recipient_email: @recipient_email,
              recipient_role: @recipient_role,
              anonymized_data: anonymized_data)
        .mail_anonymized_data
        .deliver_later
    rescue StandardError => e
      puts "Do something with #{e.inspect}, but don't crash the dashboard at any cost"
    end
  end

  private

  def anonymize_data
    case @entity_type
    when 'district'
      anonymize_district_data
    when 'facility'
      anonymize_facility_data
    else
      raise "Error: Unknown entity type: #{entity_type}"
    end
  end

  def anonymize_district_data
    organization_district = OrganizationDistrict.new(@entity_map[:district_name], Organization.find(@entity_map[:organization_id]))
    patients_in_organization = organization_district.facilities.flat_map { |f| f.patients }

    csv_data = Hash.new
    patients_csv = CSV.generate(headers: true) do |csv|
      csv << AnonymizedDataConstants.patient_headers.map(&:titleize)

      patients_in_organization.each do |patient|
        user_id = User.where(id: patient.registration_user_id).first
        facility_name = Facility.where(id: patient.registration_facility_id).first&.name

        csv << [
          hash_uuid(patient.id),
          patient.created_at,
          patient.recorded_at,
          if facility_name.blank?
            'null'
          else
            facility_name
          end,
          if user_id.blank?
            'null'
          else
            hash_uuid(user_id)
          end,
          patient.age,
          patient.gender
        ]
      end
    end

    csv_data[AnonymizedDataConstants::PATIENTS_FILE] = patients_csv
    csv_data
  end

  def anonymize_facility_data
    facility = Facility.find(@entity_map[:facility_id])
    patients_in_facility = facility.patients

    csv_data = Hash.new
    csv_data
  end

  def hash_uuid(original_uuid)
    UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, { uuid: original_uuid }.to_s).to_s
  end

  module CSVOperations
  end

  module AnonymizedDataConstants
    PATIENTS_FILE = 'patients.csv'
    BPS_FILE = 'blood_pressures.csv'
    MEDICINES_FILE = 'medicines.csv'
    APPOINTMENTS_FILE = 'appointments.csv'
    OVERDUES_FILE = 'overdue_appointments.csv'
    COMMUNICATIONS_FILE = 'communications.csv'

    def self.patient_headers
      %w[id created_at registration_date facility_name user_id age gender]
    end

    def self.bp_headers
      %w[id patient_id created_at bp_date facility_name user_id bp_reading]
    end

    def self.medicines_headers
      %w[id patient_id created_at facility_name user_id medicine_name dosage]
    end

    def self.appointment_headers
      %w[id patient_id created_at facility_name user_id appointment_date]
    end

    def self.overdue_headers
      %w[id patient_id created_at facility_name user_id agreed to visit remind_to_call_later removed_from_overdue_list]
    end

    def self.communications_headers
      %w[id appointment_id patient_id user_id created_at communication_type communication_result]
    end
  end
end
