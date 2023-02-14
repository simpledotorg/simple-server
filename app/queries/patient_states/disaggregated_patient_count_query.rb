class PatientStates::DisaggregatedPatientCountQuery
  attr_reader :query, :conn

  def initialize(query)
    @query = query
    @conn = ActiveRecord::Base
  end

  def disaggregate_by_gender
    query.group(:gender)
  end

  def disaggregate_by_age(buckets)
    query.group(conn.sanitize_sql_array(["width_bucket(current_age, ARRAY[?])", buckets]))
  end
end
