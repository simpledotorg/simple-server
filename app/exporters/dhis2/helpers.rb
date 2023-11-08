module Dhis2::Helpers
  def self.configure
    Dhis2.configure do |config|
      config.url = ENV.fetch("DHIS2_URL")
      config.user = ENV.fetch("DHIS2_USERNAME")
      config.password = ENV.fetch("DHIS2_PASSWORD")
      config.version = ENV.fetch("DHIS2_VERSION")
    end
  end

  def self.send_data_to_dhis2(data_values)
    configure
    # Rails.logger.info(data_values)
    Dhis2.client.data_value_sets.bulk_create(data_values: data_values)
  end

  def self.previous_month_period
    @previous_month_period ||= Period.current.previous
  end

  def self.last_n_month_periods(n)
    (previous_month_period.advance(months: -n + 1)..previous_month_period)
  end

  def self.htn_controlled(region, period)
    PatientStates::Hypertension::ControlledPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_cumulative_assigned(region, period)
    PatientStates::Hypertension::CumulativeAssignedPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_cumulative_assigned_adjusted(region, period)
    PatientStates::Hypertension::AdjustedAssignedPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_cumulative_registrations(region, period)
    PatientStates::Hypertension::CumulativeRegistrationsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_dead(region, period)
    PatientStates::Hypertension::DeadPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_monthly_registrations(region, period)
    PatientStates::Hypertension::MonthlyRegistrationsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_ltfu(region, period)
    PatientStates::Hypertension::LostToFollowUpPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_missed_visits(region, period)
    PatientStates::Hypertension::MissedVisitsPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_uncontrolled(region, period)
    PatientStates::Hypertension::UncontrolledPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.disaggregate_by_gender_age(patient_states, buckets)
    gender_age_counts(patient_states, buckets).transform_keys do |(gender, age_bucket_index)|
      gender_age_range_key(gender, buckets, age_bucket_index)
    end
  end

  def self.gender_age_counts(patient_states, buckets)
    PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_age(
      buckets,
      PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_gender(patient_states)
    ).count
  end

  def self.gender_age_range_key(gender, buckets, age_bucket_index)
    age_range_start = buckets[age_bucket_index - 1]
    if age_range_start == buckets.last
      "#{gender}_#{age_range_start}_plus"
    else
      age_range_end = buckets[age_bucket_index] - 1
      "#{gender}_#{age_range_start}_#{age_range_end}"
    end
  end

  def self.reporting_period(month_period)
    if Flipper.enabled?(:dhis2_use_ethiopian_calendar)
      EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(month_period).to_s(:dhis2)
    else
      month_period.to_s(:dhis2)
    end
  end

  def self.format_facility_period_data(facility_data, facility_identifier, period, data_elements_map)
    formatted_facility_data = []
    facility_data.each do |data_element, value|
      formatted_facility_data << {
        data_element: data_elements_map[data_element],
        org_unit: facility_identifier.identifier,
        period: reporting_period(period),
        value: value
      }
    end
    formatted_facility_data
  end

  def self.format_disaggregated_facility_period_data(facility_data, facility_identifier, period, data_elements_map, category_option_combo_ids)
    formatted_facility_data = []
    facility_data.each do |data_element, values|
      category_option_combo_ids.each do |combo, id|
        formatted_facility_data << {
          data_element: data_elements_map[data_element],
          org_unit: facility_identifier.identifier,
          category_option_combo: id,
          period: reporting_period(period),
          value: values.with_indifferent_access[combo] || 0
        }
      end
    end
    formatted_facility_data
  end
end
