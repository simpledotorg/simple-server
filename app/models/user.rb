class User < ApplicationRecord
  belongs_to :facility
  has_many :blood_pressures
  has_many :patients, through: :blood_pressures

  validates :full_name, presence: true
  validates :phone_number, presence: true
  validates :security_pin_hash, presence: true
end
