class Admin < ApplicationRecord
  devise :database_authenticatable, :invitable, :lockable, :recoverable,
         :rememberable, :timeoutable, :trackable, :validatable

  enum role: [
    :owner,
    :supervisor,
    :analyst,
    :organization_owner,
    :counsellor
  ]

  validates :role, presence: true

  has_many :admin_access_controls

  def facility_groups
    return admin_access_controls.map(&:access_controllable) if (supervisor? || analyst? || counsellor?)
    return organizations.flat_map(&:facility_groups) if organization_owner?
    return FacilityGroup.all if owner?
    []
  end

  def organizations
    return facility_groups.map(&:organization).uniq if (supervisor? || analyst? || counsellor?)
    return admin_access_controls.map(&:access_controllable) if organization_owner?
    return Organization.all if owner?
    []
  end

  def protocols
    facility_groups.map(&:protocol).uniq
  end

  def facilities
    facility_groups.flat_map(&:facilities)
  end

  def users
    facility_groups.flat_map(&:users)
  end
end
