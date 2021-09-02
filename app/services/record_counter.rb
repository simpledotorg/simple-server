class RecordCounter
  MODELS_TO_COUNT = [
    Appointment,
    BloodPressure,
    BloodSugar,
    Facility,
    FacilityGroup,
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
    MODELS_TO_COUNT.each do |model|
      metrics.gauge(model.to_s, model.count)
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
