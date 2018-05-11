class PhoneNumber < ApplicationRecord
  PHONE_TYPE = %w[mobile landline].freeze
  validates_presence_of :number, :created_at, :updated_at
  has_many :patient_phone_numbers
  has_many :patients, through: :patient_phone_numbers
end
