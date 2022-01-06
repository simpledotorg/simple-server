# frozen_string_literal: true

module BloodPressureable
  extend ActiveSupport::Concern

  THRESHOLDS = BloodPressure::THRESHOLDS

  included do
    scope :hypertensive, (lambda do
      where("systolic >= ? OR diastolic >= ?",
        THRESHOLDS[:hypertensive][:systolic],
        THRESHOLDS[:hypertensive][:diastolic])
    end)

    scope :under_control, (lambda do
      where("systolic < ? AND diastolic < ?",
        THRESHOLDS[:hypertensive][:systolic],
        THRESHOLDS[:hypertensive][:diastolic])
    end)
  end
end
