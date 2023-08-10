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

  def translate_id(id)
    Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, id)
  end

  def translate_facility_id(id)
    FacilityBusinessIdentifier.where(identifier_type: :external_org_facility_id, identifier: id).take.facility.id
  end
end
