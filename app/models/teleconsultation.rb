# frozen_string_literal: true

class Teleconsultation < ApplicationRecord
  include Mergeable

  belongs_to :patient
  belongs_to :medical_officer, class_name: "User", foreign_key: :medical_officer_id
  belongs_to :requested_medical_officer, class_name: "User", foreign_key: :requested_medical_officer_id, optional: true
  belongs_to :facility, optional: true
  belongs_to :requester, class_name: "User", foreign_key: :requester_id, optional: true

  has_many :prescription_drugs

  REQUEST_ATTRIBUTES = %w[requester_id facility_id requested_at requester_completion_status].freeze
  RECORD_ATTRIBUTES = %w[
    recorded_at
    teleconsultation_type
    patient_took_medicines
    patient_consented
    medical_officer_number
  ].freeze

  TELECONSULTATION_TYPES = {
    audio: "audio",
    video: "video",
    message: "message"
  }.freeze

  enum requester_completion_status: {
    yes: "yes",
    no: "no",
    waiting: "waiting"
  }, _prefix: true
  enum patient_took_medicines: {
    yes: "yes",
    no: "no"
  }, _prefix: true
  enum patient_consented: {
    yes: "yes",
    no: "no"
  }, _prefix: true
  enum teleconsultation_type: TELECONSULTATION_TYPES, _prefix: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def request
    attributes.slice(*REQUEST_ATTRIBUTES)
  end

  def record
    attributes.slice(*RECORD_ATTRIBUTES)
  end
end
