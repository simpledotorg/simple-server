class FollowUpsQuery

  def initialize(region, period_type, group: nil)
    @region = region
    @period_type = period_type
    @formatter = lambda { |v| @period_type == :quarter ? Period.quarter(v) : Period.month(v) }
  end

  def hypertension
    query = Patient.joins(:blood_pressures)
      .where("patients.recorded_at < blood_pressures.recorded_at")
      .group_by_period(@period_type, "blood_pressures.recorded_at", format: @formatter)
      .distinct
      .where(blood_pressures: {facility_id: @region.facility_ids})
      .with_hypertension
    query.group(group) if @group.present?
    query.count
  end
end
