class BulkApiImport::FhirAppointmentImporter
  include BulkApiImport::FhirImportable

  STATUS_MAPPING = {"pending" => "scheduled", "fulfilled" => "visited", "cancelled" => "cancelled"}

  def initialize(resource:, organization_id:)
    @resource = resource
    @organization_id = organization_id
    @import_user = find_or_create_import_user(organization_id)
  end

  def import
    transformed_params = Api::V3::AppointmentTransformer
      .from_request(build_attributes)
      .merge(request_metadata)

    appointment = Appointment.merge(transformed_params)
    appointment.update_patient_status

    AuditLog.merge_log(@import_user, appointment) if appointment.present?
    appointment
  end

  def request_metadata
    {user_id: @import_user.id}
  end

  def build_attributes
    {
      id: translate_id(@resource.dig(:identifier, 0, :value), org_id: @organization_id),
      patient_id: translate_id(@resource.dig(:participant, 0, :actor, :identifier), org_id: @organization_id),
      facility_id: facility_id,
      scheduled_date: scheduled_date,
      status: STATUS_MAPPING[@resource[:status]],
      appointment_type: "manual",
      creation_facility_id: @resource.dig(:appointmentCreationOrganization, :identifier) || facility_id,
      **timestamps
    }.with_indifferent_access
  end

  def facility_id
    @facility_id ||= translate_facility_id(@resource.dig(:appointmentOrganization, :identifier), org_id: @organization_id)
  end

  def scheduled_date
    @resource[:start]&.to_date&.iso8601
  end
end
