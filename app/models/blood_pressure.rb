class BloodPressure < ApplicationRecord
  include Mergeable
  include Hashable

  ANONYMIZED_DATA_FIELDS = %w[id patient_id created_at bp_date registration_facility_name user_id
                              bp_systolic bp_diastolic]

  belongs_to :patient, optional: true
  belongs_to :user, optional: true
  belongs_to :facility, optional: true

  has_one :encounter_event, as: :encounterable
  has_one :encounter, through: :encounter_event

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  scope :hypertensive, -> { where("systolic >= 140 OR diastolic >= 90") }
  scope :under_control, -> { where("systolic < 140 AND diastolic < 90") }

  def critical?
    systolic > 180 || diastolic > 110
  end

  def very_high?
    (160..179).cover?(systolic) ||
      (100..109).cover?(diastolic)
  end

  def high?
    (140..159).cover?(systolic) ||
      (90..99).cover?(diastolic)
  end

  def under_control?
    systolic < 140 && diastolic < 90
  end

  def hypertensive?
    !under_control?
  end

  def recorded_days_ago
    (Date.today - device_created_at.to_date).to_i
  end

  def to_s
    [systolic, diastolic].join("/")
  end

  def anonymized_data
    { id: hash_uuid(id),
      patient_id: hash_uuid(patient_id),
      created_at: created_at,
      bp_date: recorded_at,
      registration_facility_name: facility.name,
      user_id: hash_uuid(user_id),
      bp_systolic: systolic,
      bp_diastolic: diastolic
    }
  end
end
