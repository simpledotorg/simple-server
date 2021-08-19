class FollowUpsQuery
  def hypertension(region, period_type, group_by: nil)
    query = Patient.joins(:blood_pressures)
      .where("patients.recorded_at < #{BloodPressure.date_to_period_sql("blood_pressures.recorded_at", period_type)}")
      .group_by_period(period_type, "blood_pressures.recorded_at", format: Period.formatter(period_type))
      .distinct
      .where(blood_pressures: {facility_id: region.facility_ids})
      .with_hypertension
    if group_by.present?
      results = query.group(group_by).count
      sum_groups_per_period(results)
    else
      query.count
    end
  end

  def self.with(model_name, period, time_column: "recorded_at", at_region: nil, **groupdate_opts)
    raise ArgumentError, "Only day, month and quarter allowed" unless period.in?([:day, :month, :quarter])

    table_name = model_name.table_name.to_sym
    time_column_with_table_name = "#{table_name}.#{time_column}"

    relation = Patient.joins(table_name)
      .where("patients.recorded_at < #{model_name.date_to_period_sql(time_column_with_table_name, period)}")
      .group_by_period(period, time_column_with_table_name, groupdate_opts)
      .distinct

    if at_region.present?
      relation = relation.where(table_name => {facility_id: at_region.facilities.map(&:id)})
    end

    relation
  end

  private

  attr_reader :group_by

  def sum_groups_per_period(result)
    result.each_with_object({}) { |(key, count), hsh|
      period, field_id = *key
      hsh[period] ||= {}
      hsh[period][field_id] = count
    }
  end
end
