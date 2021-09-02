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

  def call
    MODELS_TO_COUNT.each do |model|
      metrics.gauge(model.to_s, model.count)
    end
  end

  def metrics
    @metrics ||= Metrics.with_prefix("total_counts")
  end
end
