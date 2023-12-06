module BulkApiImport::FhirImportable
  def find_or_create_import_user(org_id)
    ImportUser.find_or_create(org_id: org_id)
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
end
