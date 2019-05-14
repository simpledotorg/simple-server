class LatestBloodPressure < ApplicationRecord
  belongs_to :patient

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
end
