class BulkApiImport::Validator
  def initialize(organization:, resources:)
    @organization = organization
    @params = resources
    @resources_by_type = resources.group_by { |resource| resource[:resourceType].underscore.to_sym }
  end

  def validate
    validate_facilities.concat(validate_schema)
  end

  def validate_schema
    JSON::Validator.fully_validate(
      Api::V4::Imports.schema_with_definitions,
      @params.to_json
    )
  end

  def validate_facilities
    errors = []
    facility_ids = [
      *patient_resource_facilities,
      *appointment_resource_facilities,
      *observation_resource_facilities,
      *medication_request_resource_facilities
    ].compact.uniq

    found_facilities = FacilityBusinessIdentifier
      .joins(facility: :facility_group)
      .where(facility_business_identifiers: {identifier: facility_ids},
        facility_groups: {organization_id: @organization})
      .pluck(:identifier)

    unknown_facilities = facility_ids - found_facilities
    errors << "error: found unmapped facility IDs: #{unknown_facilities}" if unknown_facilities.present?

    errors
  end

  def patient_resource_facilities
    @resources_by_type[:patient]&.flat_map do |resource|
      [@resource.dig(:registrationOrganization, 0, :value), @resource.dig(:managingOrganization, 0, :value)]
    end
  end

  def appointment_resource_facilities
    @resources_by_type[:appointment]&.flat_map do |resource|
      [resource.dig(:appointmentOrganization, :identifier), resource.dig(:appointmentCreationOrganization, :identifier)]
    end
  end

  def observation_resource_facilities
    @resources_by_type[:observation]&.map do |resource|
      @resource[:performer][0][:identifier]
    end
  end

  def medication_request_resource_facilities
    @resources_by_type[:observation]&.map do |resource|
      @resource[:performer][0][:identifier]
    end
  end
end
