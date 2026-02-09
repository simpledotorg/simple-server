class PatientScore < ApplicationRecord
  include Mergeable
  include Discard::Model

  belongs_to :patient, optional: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
  validates :score_type, presence: true
  validates :score_value, presence: true, numericality: true

  scope :for_sync, -> { with_discarded }
end
