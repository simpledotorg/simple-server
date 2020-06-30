class ControlledPatientsQuery
  def self.call(*args)
    new(*args).call
  end

  def initialize(facilities:, time:)
    @facilities = facilities
    @time = time
  end

  attr_reader :time, :facilities

  def call
    end_range = time.end_of_month
    mid_range = time.advance(months: -1).end_of_month
    beg_range = time.advance(months: -2).end_of_month
    sub_query = LatestBloodPressuresPerPatientPerMonth
      .select("distinct on (patient_id) *")
      .under_control
      .order("patient_id, bp_recorded_at DESC, bp_id")
      .where(registration_facility_id: facilities)
      .where("(year = ? AND month = ?) OR (year = ? AND month = ?) OR (year = ? AND month = ?)",
        beg_range.year.to_s, beg_range.month.to_s,
        mid_range.year.to_s, mid_range.month.to_s,
        end_range.year.to_s, end_range.month.to_s)
    LatestBloodPressuresPerPatientPerMonth.from(sub_query, "latest_blood_pressures_per_patient_per_months")
  end
end
