class User < ApplicationRecord
  validates :name, presence: true
  validates :phone_number, presence: true
  validates :security_pin_hash, presence: true
end
