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
    FacilityBusinessIdentifier
      .joins(facility: :facility_group)
      .find_by(identifier_type: :external_org_facility_id,
        facility_business_identifiers: {identifier: id},
        facility_groups: {organization_id: org_id})
      .facility.id
  end

  def translate_patient_id(id, org_id:)
    translate_id(
      id,
      org_id: org_id,
      ns_prefix: "patient_business_identifier"
    )
  end
end
