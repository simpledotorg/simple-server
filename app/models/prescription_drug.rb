# frozen_string_literal: true

class PrescriptionDrug < ApplicationRecord
  include Mergeable
  include Hashable

  ANONYMIZED_DATA_FIELDS = %w[id patient_id created_at registration_facility_name user_id medicine_name dosage]

  enum frequency: {
    OD: "OD",
    BD: "BD",
    QDS: "QDS",
    TDS: "TDS"
  }, _prefix: true

  belongs_to :facility, optional: true
  belongs_to :patient, optional: true
  belongs_to :user, optional: true
  belongs_to :teleconsultation, optional: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
  validates :is_protocol_drug, inclusion: {in: [true, false]}
  validates :is_deleted, inclusion: {in: [true, false]}

  alias_attribute :recorded_at, :device_created_at

  scope :for_sync, -> { with_discarded }

  def self.prescribed_as_of(date)
    where("device_created_at <= ?", date.end_of_day)
      .where(%(prescription_drugs.is_deleted = false OR
              (prescription_drugs.is_deleted = true AND
               prescription_drugs.device_updated_at > ?)), date.end_of_day)
  end

  def anonymized_data
    {id: hash_uuid(id),
     patient_id: hash_uuid(patient_id),
     created_at: created_at,
     registration_facility_name: facility.name,
     user_id: hash_uuid(patient&.registration_user&.id),
     medicine_name: name,
     dosage: dosage}
  end
end
