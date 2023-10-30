class FacilityBusinessIdentifier < ApplicationRecord
  belongs_to :facility

  IDENTIFIER_TYPES = {
    dhis2_org_unit_id: "dhis2_org_unit_id"
  }

  IDENTIFIER_TYPE_PREFIXES = {
    external_org_facility_id: "external_org_facility_id:"
  }

  validate :known_identifier_type?

  validates :identifier, presence: true
  validates :identifier_type, presence: true
  validates :identifier_type, uniqueness: {scope: :facility_id}
  validates :facility, presence: true

  def self.facility_id_from_identifiers(identifiers, organization_id)
    joins(facility: :facility_group)
      .where(identifier_type: "external_org_facility_id:#{organization_id}",
        facility_business_identifiers: {identifier: identifiers},
        facility_groups: {organization_id: organization_id})
  end

  private

  def known_identifier_type?
    IDENTIFIER_TYPES.value?(identifier_type) ||
      IDENTIFIER_TYPE_PREFIXES.values.any? { |prefix| identifier_type.start_with?(prefix) }
  end
end
