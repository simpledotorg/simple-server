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
  has_many :facility_groups, -> { distinct }, through: :admin_access_controls
end
