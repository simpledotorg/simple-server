class AnonymizedDataDownloadService
  def initialize(recipient_name, recipient_email, recipient_role, entity_map, entity_type)
    @recipient_name = recipient_name
    @recipient_email = recipient_email
    @recipient_role = recipient_role
    @entity_map = entity_map
    @entity_type = entity_type
  end

  def execute
    anonymized_data = anonymize_data
    binding.pry

    AnonymizedDataDownloadMailer
      .with(recipient_name: @recipient_name,
            recipient_email: @recipient_email,
            recipient_role: @recipient_role,
            anonymized_data: anonymized_data)
      .mail_anonymized_data
      .deliver_later
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
    
  end

  def anonymized_facility_data

  end

  module AnonymizedDataConstants
    def self.patient_headers
      %w[id created_at registration_date facility_name user_id age gender phone_number]
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
