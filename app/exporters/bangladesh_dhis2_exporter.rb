class BangladeshDhis2Exporter
  def initialize(region, period)
    query = PatientStatesQuery.new(region, period)
  end

  def data
    {
      cumulative_assigned_patients: query.cumulative_assigned_patients
    }
  end
end
