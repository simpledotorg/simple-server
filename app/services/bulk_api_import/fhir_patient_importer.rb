class BulkApiImport::FhirPatientImporter
  include BulkApiImport::FhirImportable

  GENDER_MAPPING = {"male" => "male", "female" => "female", "other" => "transgender"}

  def initialize(resource:, organization_id:)
    @resource = resource
    @organization_id = organization_id
  end

  def import
    merge_result = build_attributes
      .then { Api::V3::PatientTransformer.from_nested_request(_1) }
      .then { MergePatientService.new(_1, request_metadata: request_metadata).merge }

    AuditLog.merge_log(import_user, merge_result) if merge_result.present?
    merge_result
  end

  def request_metadata
    {request_user_id: import_user.id,
     request_facility_id: @resource.dig(:managingOrganization, 0, :value)}
  end

  def identifier
    @resource.dig(:identifier, 0, :value)
  end

  def build_attributes
    {
      id: translate_id(identifier, org_id: @organization_id),
      full_name: @resource.dig(:name, :text) || "Anonymous " + Faker::Name.first_name,
      gender: gender,
      status: status,
      date_of_birth: @resource[:birthDate],
      registration_facility_id: registration_facility_id,
      assigned_facility_id: assigned_facility_id,
      address: address,
      phone_numbers: phone_numbers,
      business_identifiers: business_identifiers,
      **timestamps
    }
  end

  def gender
    GENDER_MAPPING[@resource[:gender]]
  end

  def registration_facility_id
    identifier = @resource.dig(:registrationOrganization, 0, :value)
    if identifier.present?
      translate_facility_id(identifier, org_id: @organization_id)
    else
      assigned_facility_id
    end
  end

  def assigned_facility_id
    identifier = @resource.dig(:managingOrganization, 0, :value)
    translate_facility_id(identifier, org_id: @organization_id) if identifier.present?
  end

  def status
    if @resource[:deceasedBoolean]
      "dead"
    elsif @resource[:active]
      "active"
    else
      "inactive"
    end
  end

  def phone_numbers
    @resource[:telecom]&.map do |telecom|
      {
        id: translate_id(identifier, org_id: @organization_id, ns_prefix: "patient_phone_number"),
        number: telecom[:value],
        phone_type: telecom[:use] == "mobile" || telecom[:use] == "old" ? "mobile" : "landline",
        active: !(telecom[:use] == "old"),
        **timestamps
      }
    end
  end

  def address
    if (address = @resource.dig(:address, 0))
      {
        id: translate_id(identifier, org_id: @organization_id, ns_prefix: "patient_address"),
        street_address: address[:line]&.join("\n"),
        district: address[:district],
        state: address[:state],
        pin: address[:postalCode],
        **timestamps
        # lost in translation:
        #  village_or_colony
        #  zone
        #  country
      }
    end
  end

  def business_identifiers
    [
      {
        id: translate_id(identifier, org_id: @organization_id, ns_prefix: "patient_business_identifier"),
        identifier: identifier,
        identifier_type: :external_import_id,
        **timestamps
      }
    ]
  end
end
