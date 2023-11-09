module Dhis2
  module Helpers
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
end
