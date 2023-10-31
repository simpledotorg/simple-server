module BulkApiImport::FhirImportable
  def import_user
    ImportUser.find_or_create
  end

  def import
    raise NotImplementedError
  end

  def timestamps
    {
      created_at: @resource.dig(:meta, :createdAt),
      updated_at: @resource.dig(:meta, :lastUpdated)
    }
  end

  def translate_id(id, org_id:, ns_prefix: "")
    Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE + org_id + ns_prefix, id)
  end

  def translate_facility_id(id, org_id:)
    # FacilityBusinessIdentifier.find_by(identifier: id, identifier_type: :external_org_facility_id).facility.id
    FacilityBusinessIdentifier.facility_id_from_identifiers(id, org_id).take.facility.id
  end

  def translate_patient_id(id, org_id:)
    translate_id(
      id,
      org_id: org_id,
      ns_prefix: "patient_business_identifier"
    )
  end
end
