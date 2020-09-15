class Teleconsultation < ApplicationRecord
  belongs_to :patient
  belongs_to :medical_officer, class_name: "User", foreign_key: :medical_officer_id
  belongs_to :facility, optional: true
  belongs_to :requester, class_name: "User", foreign_key: :requester_id, optional: true

  REQUEST_ATTRIBUTES = %w[requester_id facility_id requested_at request_completed]
  RECORD_ATTRIBUTES = %w[recorded_at
    teleconsultation_type
    patient_took_medicines
    patient_consented
    medical_officer_number]
  TELCONSULTATION_ANSWERS = %w[yes no]
  TELCONSULTATION_TYPES = {
      audio: "audio",
      video: "video",
      message: "message"
  }.freeze

  enum patient_took_medicines: TELCONSULTATION_ANSWERS, _prefix: true
  enum patient_consented: TELCONSULTATION_ANSWERS, _prefix: true

  def request
    attributes.slice(*REQUEST_ATTRIBUTES)
  end

  def record
    attributes.slice(*RECORD_ATTRIBUTES)
  end
end
