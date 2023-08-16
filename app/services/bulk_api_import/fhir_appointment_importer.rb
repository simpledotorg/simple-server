class BulkApiImport::FhirAppointmentImporter
  include BulkApiImport::FhirImportable

  STATUS_MAPPING = {"pending" => "scheduled", "fulfilled" => "visited", "cancelled" => "cancelled"}

  def initialize(appointment_resource)
    @resource = appointment_resource
  end

  def import
    transformed_params = Api::V3::AppointmentTransformer
      .from_request(build_attributes)
      .merge(request_metadata)

    appointment = Appointment.merge(transformed_params)
    appointment.update_patient_status

    AuditLog.merge_log(import_user, appointment) if appointment.present?
    appointment
  end

  def request_metadata
    {user_id: import_user.id}
  end

  def build_attributes
    {
      id: translate_id(@resource.dig(:identifier, 0, :value)),
      patient_id: translate_id(@resource.dig(:participant, 0, :actor, :identifier)),
      facility_id: facility_id,
      scheduled_date: scheduled_date,
      status: STATUS_MAPPING[@resource[:status]],
      appointment_type: "manual",
      creation_facility_id: @resource.dig(:appointmentCreationOrganization, :identifier) || facility_id,
      **timestamps
    }.with_indifferent_access
  end

  def facility_id
    @facility_id ||= translate_facility_id(@resource.dig(:appointmentOrganization, :identifier))
  end

  def scheduled_date
    @resource[:start]&.to_date&.iso8601
  end

  def translate_facility_id(id)
    FacilityBusinessIdentifier.where(identifier_type: :external_org_facility_id, identifier: id).take.facility.id
  end
end
