class User < ApplicationRecord
  belongs_to :facility

  validates :name, presence: true
  validates :phone_number, presence: true
  validates :security_pin_hash, presence: true
end
