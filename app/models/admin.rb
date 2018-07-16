class Admin < ApplicationRecord
  devise :database_authenticatable, :lockable, :recoverable, :rememberable,
         :timeoutable, :trackable, :validatable

  enum role: [
    :admin,
    :cvho
  ]

  validates :role, presence: true
end
