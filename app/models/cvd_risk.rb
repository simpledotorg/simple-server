class CvdRisk < ApplicationRecord
  include Mergeable

  belongs_to :patient

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  scope :for_sync, -> { with_discarded }
  scope :for_patient, -> (patient_id) { where(patient_id: patient_id).order(:created_at) }
  scope :latest, -> { order(created_at: :desc).first }

  before_save :discard_previous_record

  def discard_previous_record
    most_recent = self.class.for_patient(self.patient.id).latest
    most_recent.update_columns(deleted_at: Time.now) if most_recent.present?
  end
end
