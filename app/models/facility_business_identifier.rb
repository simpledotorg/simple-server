# frozen_string_literal: true

class FacilityBusinessIdentifier < ApplicationRecord
  belongs_to :facility

  enum identifier_type: {
    dhis2_org_unit_id: "dhis2_org_unit_id"
  }

  validates :identifier, presence: true
  validates :identifier_type, presence: true
  validates :identifier_type, uniqueness: {scope: :facility_id}
  validates :facility, presence: true
end
