class BulkApiImport::FhirPatientImporter
  GENDER_MAPPING = {"male" => "male", "female" => "female", "other" => "transgender"}

  def initialize(patient_resource)
    @resource = patient_resource
  end

  def import_user
    PatientImport::ImportUser.find_or_create
  end

  def import
    transformed_params = Api::V3::PatientTransformer.from_nested_request(build_attributes)
    patient = MergePatientService.new(transformed_params, request_metadata: request_metadata).merge
    AuditLog.merge_log(import_user, patient) if patient.present?
    patient
  end

  def request_metadata
    {request_user_id: import_user.id,
     request_facility_id: @resource.dig(:managingOrganization, 0, :value)}
  end

  def build_attributes
    {
      id: translate_id(@resource.dig(:identifier, 0, :value)),
      full_name: @resource.dig(:name, :value),
      gender: gender,
      status: status,
      date_of_birth: @resource[:birthDate],
      registration_facility_id: @resource.dig(:registrationOrganization, 0, :value),
      assigned_facility_id: @resource.dig(:managingOrganization, 0, :value),
      address: address,
      phone_numbers: phone_numbers,
      business_identifiers: business_identifiers,
      **timestamps
    }
  end

  def timestamps
    {
      created_at: @resource.dig(:meta, :createdAt),
      updated_at: @resource.dig(:meta, :lastUpdated)
    }
  end

  def gender
    GENDER_MAPPING[@resource[:gender]]
  end

  def status
    "dead" if @resource[:deceasedBoolean]
    @resource[:active] ? "active" : "inactive"
  end

  def phone_numbers
    @resource[:telecom]&.map do |telecom|
      {
        id: SecureRandom.uuid,
        number: telecom[:value],
        phone_type: telecom[:use] == "mobile" || telecom[:use] == "inactive" ? "mobile" : "landline",
        active: !(telecom[:use] == "inactive"),
        **timestamps
      }
    end
  end

  def address
    if (address = @resource.dig(:address, 0))
      {
        id: SecureRandom.uuid,
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
        id: SecureRandom.uuid,
        identifier: @resource.dig(:identifier, 0, :value),
        identifier_type: :external_import_id,
        **timestamps
      }
    ]
  end

  def translate_id(id)
    Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, id)
  end
end
