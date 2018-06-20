class PrescriptionDrug < ApplicationRecord
  include Mergeable

  belongs_to :facility, optional: true
  belongs_to :patient, optional: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
  validates :is_protocol_drug, inclusion: { in: [ true, false ] }
  validates :is_deleted, inclusion: { in: [ true, false ] }
end
