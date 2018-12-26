class Admin < ApplicationRecord
  devise :database_authenticatable, :invitable, :lockable, :recoverable,
         :rememberable, :timeoutable, :trackable, :validatable

  enum role: [
    :owner,
    :supervisor,
    :analyst
  ]

  validates :role, presence: true

  has_many :admin_access_controls

  def facility_groups
    if supervisor?
      return admin_access_controls.map(&:access_controllable)
    end
    []
  end
end
