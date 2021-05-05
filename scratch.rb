Patient.hypertension_follow_ups_by_period(period, at_region: region, current: include_current_period, last: last)
# calls ->
scope :hypertension_follow_ups_by_period, ->(period, at_region: nil, current: true, last: nil) {
  follow_ups_with(BloodPressure, period, at_region: at_region, current: current, last: last)
    .with_hypertension
}
# calls ->
def self.follow_ups_with(model_name, period, time_column: "recorded_at", at_region: nil, current: true, last: nil)
  table_name = model_name.table_name.to_sym
  time_column_with_table_name = "#{table_name}.#{time_column}"

  relation = joins(table_name)
    .where("patients.recorded_at < #{model_name.date_to_period_sql(time_column_with_table_name, period)}")
    .group_by_period(period, time_column_with_table_name, current: current, last: last)
    .distinct

  if at_region.present?
    facility_ids = at_region.facilities.map(&:id)
    relation = relation.where(table_name => {facility_id: facility_ids})
  end

  relation
end
