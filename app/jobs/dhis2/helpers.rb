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
  end
end
