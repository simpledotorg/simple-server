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

    unless error.present?
      error = validate_observation_codes
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

  def validate_observation_codes
    invalid_observations = resources_by_type[:observation]&.map do |observation|
      identifier = observation[:identifier][0][:value]
      observation_codes = observation[:component]&.map { |component| component.dig(:code, :coding, 0, :code) }
      next if valid_blood_pressure_codes?(observation_codes) || valid_blood_sugar_codes?(observation_codes)
      [identifier, observation_codes]
    end&.compact&.to_h

    if invalid_observations.present?
      {
        invalid_observation_codes_error: {
          invalid_observations: invalid_observations,
          message: <<~ERRSTRING
            Invalid set of codes for the following identifiers: #{invalid_observations.pretty_inspect}.
            For blood pressure observation: Ensure that both systolic and diastolic measurements are present with the correct codes.
            For blood sugar observations: Ensure that only one code is present and matching the list of accepted codes."
          ERRSTRING
        }
      }
    end
  end

  def valid_blood_pressure_codes?(codes)
    codes.to_set == Api::V4::Imports::ALLOWED_BP_CODES.to_set
  end

  def valid_blood_sugar_codes?(codes)
    codes.count == 1 && Api::V4::Imports::ALLOWED_BS_CODES.include?(codes.first)
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
      .where(identifier_type: "external_org_facility_id:#{@organization.id}",
        facility_business_identifiers: {identifier: facility_ids},
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
