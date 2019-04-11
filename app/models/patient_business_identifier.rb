class PatientBusinessIdentifier < ApplicationRecord
  belongs_to :patient

  enum identifier_type: {
    simple_bp_passport: 'simple_bp_passport'
  }

  validates :identifier, presence: true
  validates :identifier_type, presence: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
end