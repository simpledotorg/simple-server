class BulkApiImport::Validator
  def initialize(organization:, resources:)
    @organization = organization
    @params = resources
  end

  def validate
    error = validate_schema
    unless error.present?
      error = validate_facilities
    end

    error
  end

  def validate_schema
    schema_errors = JSON::Validator.fully_validate(
      Api::V4::Imports.schema_with_definitions,
      @params.to_json
    )
    {schema_errors: schema_errors} if schema_errors.present?
  end

  def validate_facilities
    facility_ids = [
      *patient_resource_facilities,
      *appointment_resource_facilities,
      *observation_resource_facilities,
      *medication_request_resource_facilities
    ]

    found_facilities = FacilityBusinessIdentifier
      .joins(facility: :facility_group)
      .where(facility_business_identifiers: {identifier: facility_ids},
        facility_groups: {organization_id: @organization})
      .pluck(:identifier)

    unknown_facilities = facility_ids - found_facilities
    {invalid_facility_error: "found unmapped facility IDs: #{unknown_facilities}"} if unknown_facilities.present?
  end

  def patient_resource_facilities
    resources_by_type[:patient]&.flat_map do |resource|
      [resource.dig(:registrationOrganization, 0, :value), resource.dig(:managingOrganization, 0, :value)]
    end&.compact&.uniq
  end

  def appointment_resource_facilities
    resources_by_type[:appointment]&.flat_map do |resource|
      [resource.dig(:appointmentOrganization, :identifier), resource.dig(:appointmentCreationOrganization, :identifier)]
    end&.compact&.uniq
  end

  def observation_resource_facilities
    resources_by_type[:observation]&.map do |resource|
      resource[:performer][0][:identifier]
    end&.compact&.uniq
  end

  def medication_request_resource_facilities
    resources_by_type[:medication_request]&.map do |resource|
      resource[:performer][:identifier]
    end&.compact&.uniq
  end

  private

  def resources_by_type
    @resources_by_type ||= @params.group_by { |resource| resource[:resourceType].underscore.to_sym }
  end
end
