class PrescriptionDrug < ApplicationRecord
  include Mergeable
  include Hashable

  ANONYMIZED_DATA_FIELDS = %w[id patient_id created_at registration_facility_name user_id medicine_name dosage]

  belongs_to :facility, optional: true
  belongs_to :patient, optional: true

  has_one :encounter_event, as: :encountered
  has_one :encounter, through: :encounter_event

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
  validates :is_protocol_drug, inclusion: { in: [true, false] }
  validates :is_deleted, inclusion: { in: [true, false] }

  def anonymized_data
    { id: hash_uuid(id),
      patient_id: hash_uuid(patient_id),
      created_at: created_at,
      registration_facility_name: facility.name,
      user_id: hash_uuid(patient&.registration_user&.id),
      medicine_name: name,
      dosage: dosage,
    }
  end
end
