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

  def translate_id(id, ns_prefix: "")
    Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE + ns_prefix, id)
  end

  def translate_facility_id(id)
    FacilityBusinessIdentifier.find_by(identifier: id, identifier_type: :external_org_facility_id).facility.id
  end
end
