class AdminAccessControl < ApplicationRecord
  belongs_to :admin, class_name: 'User', foreign_key: :user_id
  belongs_to :access_controllable, polymorphic: true

  ACCESS_CONTROLLABLE_TYPE_FOR_ROLE = {
    analyst: 'FacilityGroup',
    supervisor: 'FacilityGroup',
    counsellor: 'FacilityGroup',
    organization_owner: 'Organization'
  }

  validates :admin, presence: true
end
