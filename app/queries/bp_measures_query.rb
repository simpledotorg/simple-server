class BPMeasuresQuery
  def count(region, period_type, diagnosis: :hypertension, group_by: nil)
    BloodPressure
      .joins(:patient).merge(Patient.with_hypertension)
      .group_by_period(period_type, :recorded_at, {format: Period.formatter(period_type)})
      .where(facility: region.facilities)
      .count
  end
end
