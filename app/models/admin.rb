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
    return admin_access_controls.map(&:access_controllable).flat_map(:facility_groups) if organization_owner?
    []
  end

  def organizations
    return admin_access_controls.map(&:access_controllable).map(&:organization).uniq if (supervisor? || analyst?)
    return admin_access_controls.map(&:access_controllable) if organization_owner?
    []
  end
end
