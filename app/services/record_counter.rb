# frozen_string_literal: true

class RecordCounter
  MODELS_TO_COUNT = [
    Appointment,
    BloodPressure,
    BloodSugar,
    Encounter,
    Facility,
    FacilityGroup,
    MedicalHistory,
    Notification,
    Patient,
    Region,
    User
  ]

  def self.call
    new.call
  end

  attr_reader :metrics

  def initialize
    @metrics ||= Metrics.with_prefix("counts")
  end

  def call
    count_totals
    count_per_region_totals
  end

  private

  def count_totals
    MODELS_TO_COUNT.each do |model|
      metrics.gauge(model.to_s, model.count)
    end
  end

  def count_per_region_totals
    Region.district_regions.find_each do |district|
      count = district.facilities.count
      metrics.histogram("facilities_per_district", count)
    end
    Region.facility_regions.find_each do |facility|
      count = facility.assigned_patients.count
      metrics.histogram("assigned_patients_per_facility", count)
    end
    Region.block_regions.find_each.each do |block|
      count = block.assigned_patients.count
      metrics.histogram("assigned_patients_per_block", count)
    end
  end
end
