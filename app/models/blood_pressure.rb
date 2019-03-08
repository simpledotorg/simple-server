class BloodPressure < ApplicationRecord
  include Mergeable

  belongs_to :facility, optional: true
  belongs_to :patient, optional: true
  belongs_to :user, optional: true

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

  def recorded_days_ago
    (Date.today - device_created_at.to_date).to_i
  end

  def to_s
    [systolic, diastolic].join("/")
  end
end
