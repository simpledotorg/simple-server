class PrescriptionDrug < ApplicationRecord
  include Mergeable
  include Hashable

  ANONYMIZED_DATA_FIELDS = %w[id patient_id created_at facility_name user_id medicine_name dosage]

  belongs_to :facility, optional: true
  belongs_to :patient, optional: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
  validates :is_protocol_drug, inclusion: { in: [true, false] }
  validates :is_deleted, inclusion: { in: [true, false] }

  def anonymized_data
    user_id = patient&.registration_user_id
    facility_name = Facility.where(id: facility_id).first&.name

    {
      id: hash_uuid(id),
      patient_id: hash_uuid(patient_id),
      created_at: created_at,
      facility_name: facility_name,
      user_id: hash_uuid(user_id),
      medicine_name: name,
      dosage: dosage,
    }
  end
end
