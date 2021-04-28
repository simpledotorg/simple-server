class FollowUpsQuery
  def initialize(region, period_type, group: nil)
    @region = region
    @period_type = period_type
    @group = group
    @formatter = lambda { |v| @period_type == :quarter ? Period.quarter(v) : Period.month(v) }
  end

  def encounters
    Patient.joins(:encounters)
      .where("patients.recorded_at < encounters.encountered_on")
      .group_by_period(@period_type, "encounters.encountered_on", format: @formatter)
      .distinct
      .where(encounters: {facility_id: @region.facility_ids})
      .count
  end

  def hypertension
    Rails.logger.info "RJS getting hypertension followups with group: #{@group}"
    query = Patient.joins(:blood_pressures)
      .where("patients.recorded_at < #{BloodPressure.date_to_period_sql("blood_pressures.recorded_at", @period_type)}")
      .group_by_period(@period_type, "blood_pressures.recorded_at", format: @formatter)
      .distinct
      .where(blood_pressures: {facility_id: @region.facility_ids})
      .with_hypertension
    query = query.group(@group) if @group.present?
    query.count
  end
end
