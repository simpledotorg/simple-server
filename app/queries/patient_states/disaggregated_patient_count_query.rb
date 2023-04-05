module PatientStates
  class DisaggregatedPatientCountQuery
    def self.disaggregate_by_gender(query)
      query.group(:gender)
    end

    def self.disaggregate_by_age(buckets, query)
      query.group(ActiveRecord::Base.sanitize_sql_array(["width_bucket(current_age, ARRAY[?])", buckets]))
    end

    def self.bucket_index_to_range(bucket_starts, step, index)
      [bucket_starts[index], bucket_starts[index] + step - 1]
    end
  end
end
