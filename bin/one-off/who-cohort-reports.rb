require 'csv'
file = "/home/deploy/who_stats.csv"

def registered(facilities, cohort_start, cohort_end)
  Patient.select(%Q(
    patients.*,
    oldest_bps.device_created_at as first_bp_date,
    oldest_bps.systolic as first_systolic,
    oldest_bps.diastolic as first_diastolic
  )).joins(%Q(
    INNER JOIN (
      SELECT DISTINCT ON (patient_id) *
      FROM blood_pressures
      WHERE device_created_at >= '#{cohort_start}'
      AND device_created_at <= '#{cohort_end}'
      AND facility_id IN ('#{Array(facilities).map(&:id).join('\',\'')}')
      ORDER BY patient_id, device_created_at ASC
    ) as oldest_bps
    ON oldest_bps.patient_id = patients.id
  ))
end

def visited(patients, quarter_start, quarter_end)
  patients.select(%Q(
    patients.*,
    newest_bps.device_created_at as last_bp_date,
    newest_bps.systolic as last_systolic,
    newest_bps.diastolic as last_diastolic
  )).joins(%Q(
    INNER JOIN (
      SELECT DISTINCT ON (patient_id) *
      FROM blood_pressures
      WHERE device_created_at >= '#{quarter_start}'
      AND device_created_at <= '#{quarter_end}'
      ORDER BY patient_id, device_created_at DESC
    ) as newest_bps
    ON newest_bps.patient_id = patients.id
  ))
end

def controlled(patients)
  patients.select { |p| p.last_systolic < 140 && p.last_diastolic < 90 }
end

def uncontrolled(patients)
  patients.select { |p| p.last_systolic >= 140 || p.last_diastolic >= 90 }
end

def cohort_stats(facility, cohort_start, cohort_end, quarter_start, quarter_end)
  f_registered = registered(facility, cohort_start, cohort_end)
  f_visited = visited(f_registered, quarter_start, quarter_end)
  f_controlled = controlled(f_visited)
  f_uncontrolled = uncontrolled(f_visited)

  {
    registered: f_registered.size,
    visited: f_visited.size,
    controlled: f_controlled.size,
    uncontrolled: f_uncontrolled.size,
    defaulted: f_registered.size - f_visited.size
  }
end

facilities = Facility.where(district: "Bathinda")

quarter_start = Date.new(2019, 1, 1).beginning_of_day
quarter_end = Date.new(2019, 3, 31).end_of_day

headers = [
  "Facility", "Type", "District", "State",
  "Jan-Dec 2018: Registered", "Jan-Dec 2018: Visited Jan-Mar 2019", "Jan-Dec 2018: Controlled Jan-Mar 2019", "Jan-Dec 2018: Uncontrolled Jan-Mar 2019", "Jan-Dec 2018: Defaulted Jan-Mar 2019",
  "Jul-Sep 2018: Registered", "Jul-Sep 2018: Visited Jan-Mar 2019", "Jul-Sep 2018: Controlled Jan-Mar 2019", "Jul-Sep 2018: Uncontrolled Jan-Mar 2019", "Jul-Sep 2018: Defaulted Jan-Mar 2019",
  "Oct-Dec 2018: Registered", "Oct-Dec 2018: Visited Jan-Mar 2019", "Oct-Dec 2018: Controlled Jan-Mar 2019", "Oct-Dec 2018: Uncontrolled Jan-Mar 2019", "Oct-Dec 2018: Defaulted Jan-Mar 2019"
]

CSV.open(file, "w", write_headers: true, headers: headers) do |csv|
  facilities.each do |facility|
    # annual
    cohort_start = Date.new(2018, 1, 1).beginning_of_day
    cohort_end = Date.new(2018, 12, 31).end_of_day
    annual_stats = cohort_stats(facility, cohort_start, cohort_end, quarter_start, quarter_end)

    # 6-9 month
    cohort_start = Date.new(2018, 7, 1).beginning_of_day
    cohort_end = Date.new(2018, 9, 30).end_of_day
    six_nine_stats = cohort_stats(facility, cohort_start, cohort_end, quarter_start, quarter_end)

    # 3-6 month
    cohort_start = Date.new(2018, 10, 1).beginning_of_day
    cohort_end = Date.new(2018, 12, 31).end_of_day
    three_six_stats = cohort_stats(facility, cohort_start, cohort_end, quarter_start, quarter_end)

    csv << [
      facility.name.strip, facility.facility_type.strip, facility.district.strip, facility.state.strip,
      *annual_stats.values_at(:registered, :visited, :controlled, :uncontrolled, :defaulted),
      *six_nine_stats.values_at(:registered, :visited, :controlled, :uncontrolled, :defaulted),
      *three_six_stats.values_at(:registered, :visited, :controlled, :uncontrolled, :defaulted)
    ]
  end
end
