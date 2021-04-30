class WhoReportService

  def initialize(region, period)
    @region = region
    @period = period
    @months = @period.downto(5).reverse
    @dashboard_analytics = @region.dashboard_analytics(period: @period.type, prev_periods: 6)
    regions = @region.facility_regions.to_a << @region
    repo = Reports::Repository.new(regions, periods: @period)
    @region_data = populate_region_data(@region, repo)
    @facilities_data = @region.facility_regions.map do |facility|
      populate_region_data(facility, repo)
    end
  end

  def populate_region_data(region, repo)
    slug = region.slug
    region_data= Hash.new(0)
    region_data[:region] = region
    region_data[:adjusted_patient_counts] = repo.adjusted_patient_counts[slug]
    region_data[:controlled_patients_rate] = repo.controlled_patients_rate[slug]
    region_data[:uncontrolled_patients_rate] = repo.uncontrolled_patients_rate[slug]
    region_data[:missed_visits_rate] = repo.missed_visits_rate[slug]
    region_data[:cumulative_patients] = repo.cumulative_assigned_patients_count[slug]
    region_data[:cumulative_registrations] = repo.cumulative_registrations[slug]
    region_data[:ltfu_counts] = repo.ltfu_counts[slug]
    region_data[:visited_without_bp_taken_rate] = repo.visited_without_bp_taken_rate[slug]
    region_data
  end

  def report
  csv = CSV.generate(headers: true) do |csv|
    csv << ["Facility Report #{@period.to_date.strftime("%B %Y")}"]

    section_labels = [
      *Array.new(12, nil),
      "New Registrations",
      *Array.new(5, nil),
      "Follow Up",
      *Array.new(5, nil),
      "Cumulative treatment outcome among patient under care",
      *Array.new(3, nil),
      "Drug availability",
      *Array.new(2, nil)
    ]
    csv << section_labels

    # HEADERS
    month_labels = @months.map { |month| month.value.strftime("%b-%Y") }
    csv << [
      "Sr. No",
      "Name of the District",
      "Name of the Facility",
      "Type of Facility",
      "Name of the Block",
      "Active/Inactive (Inactive facilities have 0 BP measures taken)",
      "Est. HTN Population",
      "Total Reg",
      "Total Assigned Patients",
      "Total LTFU",
      "Died",
      "Total Patients under Care",
      month_labels,
      month_labels,
      "BP Controlled",
      "BP not Controlled",
      "Missed Visit",
      "Visited but BP not taken",
      "Amlodipine",
      "ARBs/ACE Inhibitors",
      "Diuretic"
    ].flatten

    # DISTRICT ROW
    dead = Patient.where(assigned_facility_id: @region.facilities.pluck(:id), status: "dead").count
    registered_by_month = @months.map do |month|
      @dashboard_analytics.sum { |_, data| data.dig(:registered_patients_by_period, month.value) || 0 }
    end
    follow_up_by_month = @months.map do |month|
      @dashboard_analytics.sum { |_, data| data.dig(:follow_up_patients_by_period, month.value) || 0 }
    end
    csv << [
      "All",
      @region.name,
      *Array.new(5, nil),
      @region_data.dig(:cumulative_registrations, @period),
      @region_data.dig(:cumulative_patients, @period),
      @region_data.dig(:ltfu_counts, @period),
      dead,
      @region_data.dig(:adjusted_patient_counts, @period),
      *registered_by_month,
      *follow_up_by_month,
      @region_data.dig(:controlled_patients_rate, @period),
      @region_data.dig(:uncontrolled_patients_rate, @period),
      @region_data.dig(:missed_visits_rate, @period),
      @region_data.dig(:visited_without_bp_taken_rate, @period),
      *Array.new(3, nil)
    ]

    # FACILITY ROWS
    @region.facility_regions.each_with_index do |facility, index|
      analytics_data = @dashboard_analytics[facility.id]
      dead = Patient.where(assigned_facility_id: facility.id, status: "dead").count
      registration_numbers = []
      follow_up_numbers = []

      @months.each do |month|
        registration_numbers << (@dashboard_analytics.dig(facility.id, :registered_patients_by_period, month.value) || 0)
        follow_up_numbers << (@dashboard_analytics.dig(facility.id, :follow_up_patients_by_period, month.value) || 0)
      end

      matching_facility = @facilities_data.find{ |fac| fac[:region] == facility }
      csv << [
        index + 1,
        @region.name,
        facility.name,
        facility.source.facility_type,
        facility.source.block,
        facility.source.blood_pressures.any? ? "Active" : "Inactive",
        nil,
        matching_facility.dig(:cumulative_registrations, @period),
        matching_facility.dig(:cumulative_patients, @period),
        matching_facility.dig(:ltfu_counts, @period),
        dead,
        matching_facility.dig(:ltfu_counts, @period),
        *registration_numbers,
        *follow_up_numbers,
        matching_facility.dig(:controlled_patients_rate, @period),
        matching_facility.dig(:uncontrolled_patients_rate, @period),
        matching_facility.dig(:missed_visits_rate, @period),
        matching_facility.dig(:visited_without_bp_taken_rate, @period),
        *Array.new(3, nil)
      ]
    end
  end
  end
end