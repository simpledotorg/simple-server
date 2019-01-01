class Admin < ApplicationRecord
  devise :database_authenticatable, :invitable, :lockable, :recoverable,
         :rememberable, :timeoutable, :trackable, :validatable

  enum role: [
    :owner,
    :supervisor,
    :analyst,
    :organization_owner
  ]

  validates :role, presence: true

  has_many :admin_access_controls

  def facility_groups
    return admin_access_controls.map(&:access_controllable) if (supervisor? || analyst?)
    return admin_access_controls.map(&:access_controllable).flat_map(&:facility_groups) if organization_owner?
    return FacilityGroup.all if owner?
    []
  end

  def organizations
    return facility_groups.map(&:organization).uniq if (supervisor? || analyst?)
    return admin_access_controls.map(&:access_controllable) if organization_owner?
    return Organization.all if owner?
    []
  end

  def protocols
    organizations.flat_map(&:protocols)
  end

  def users
    facility_groups.flat_map(&:users)
  end

  def self.have_common_organization(admin1, admin2)
    (admin1.organizations & admin2.organizations).present?
  end
end
