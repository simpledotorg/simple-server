class MedicalHistory < ApplicationRecord
  include Mergeable
  belongs_to :patient, optional: true
  
  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
end
