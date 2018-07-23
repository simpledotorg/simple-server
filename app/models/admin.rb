class Admin < ApplicationRecord
  devise :database_authenticatable, :lockable, :recoverable, :rememberable,
         :timeoutable, :trackable, :validatable

  enum role: [
    :owner,
    :supervisor
  ]

  validates :role, presence: true
end
