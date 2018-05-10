class PhoneNumber < ApplicationRecord
  PHONE_TYPE = %w[mobile landline].freeze
  validates_presence_of :number, :created_at, :updated_at
  has_and_belongs_to_many :patients
end
