module PatientStates
  class DisaggregatedPatientCountQuery
    def self.disaggregate_by_gender(query)
      query.group(:gender)
    end

    def self.disaggregate_by_age(buckets, query)
      query.group(ActiveRecord::Base.sanitize_sql_array(["width_bucket(current_age, ARRAY[?])", buckets]))
    end
  end
end
