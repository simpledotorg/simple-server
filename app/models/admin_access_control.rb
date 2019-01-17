class AdminAccessControl < ApplicationRecord
  belongs_to :admin
  belongs_to :access_controllable, polymorphic: true

  ACCESS_CONTROLLABLE_TYPE_FOR_ROLE = {
    analyst: 'FacilityGroup',
    supervisor: 'FacilityGroup',
    healthcare_counsellor: 'FacilityGroup',
    organization_owner: 'Organization'
  }

  validates :admin, presence: true
end
