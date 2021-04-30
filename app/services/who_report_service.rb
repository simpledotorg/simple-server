class WhoReportService
  attr_reader :region, :period, :months, :repo, :dashboard_analytics
  def initialize(region, period)
    @region = region
    @period = period
    @months = period.downto(5).reverse
    regions = region.facility_regions.to_a << region
    @repo = Reports::Repository.new(regions, periods: period)
    @dashboard_analytics = region.dashboard_analytics(period: period.type, prev_periods: 6)
  end

  def report
    csv = CSV.generate(headers: true) { |csv|
      csv << ["Facility Report #{period.to_date.strftime("%B %Y")}"]
      csv << section_labels
      csv << header_row
      csv << district_row
      facility_rows.each do |row|
        csv << row
      end
    }
  end

  private

  def section_labels
    [
      Array.new(12, nil),
      "New Registrations",
      Array.new(5, nil),
      "Follow-up patients",
      Array.new(5, nil),
      "Treatment outcomes of patients under care",
      Array.new(3, nil),
      "Drug availability",
      Array.new(2, nil)
    ].flatten
  end

  def header_row
    month_labels = months.map { |month| month.value.strftime("%b-%Y") }
    [
      "#",
      "District",
      "Facility",
      "Facility type",
      "Block",
      "Active/Inactive (Inactive facilities have 0 BP measures taken)",
      "Estimated hypertension opulation",
      "Total registrations",
      "Total assigned patients",
      "Total lost to follow-up",
      "Died",
      "Total patients under care",
      month_labels,
      month_labels,
      "BP controlled %",
      "BP not controlled %",
      "Missed visits %",
      "Visit but no BP taken %",
      "Amlodipine",
      "ARBs/ACE Inhibitors",
      "Diuretic"
    ].flatten
  end

  def district_row
    region_data = populate_region_data(region)
    registered_by_month = months.map { |month|
      dashboard_analytics.sum { |_, data| data.dig(:registered_patients_by_period, month.value) || 0 }
    }
    follow_up_by_month = months.map { |month|
      dashboard_analytics.sum { |_, data| data.dig(:follow_up_patients_by_period, month.value) || 0 }
    }
    patients = Patient.with_hypertension.where(assigned_facility: region.facilities.pluck(:id))

    [
      "All",
      region.name,
      Array.new(5, nil),
      region_data.dig(:cumulative_registrations, period),
      patients.excluding_dead.count,
      region_data.dig(:ltfu_counts, period),
      patients.status_dead.count,
      patients.excluding_dead.not_ltfu_as_of(period.end).count,
      registered_by_month,
      follow_up_by_month,
      region_data.dig(:controlled_patients, period),
      region_data.dig(:uncontrolled_patients, period),
      region_data.dig(:missed_visits, period),
      region_data.dig(:visited_without_bp_taken, period),
      Array.new(3, nil)
    ].flatten
  end

  def facility_rows
    facilities_data = region.facility_regions.map { |facility|
      populate_region_data(facility)
    }
    region.facility_regions.map.with_index do |facility, index|
      analytics_data = dashboard_analytics[facility.id]
      registration_numbers = []
      follow_up_numbers = []

      months.each do |month|
        registration_numbers << (dashboard_analytics.dig(facility.id, :registered_patients_by_period, month.value) || 0)
        follow_up_numbers << (dashboard_analytics.dig(facility.id, :follow_up_patients_by_period, month.value) || 0)
      end
      patients = Patient.with_hypertension.where(assigned_facility: facility.source)

      matching_facility = facilities_data.find { |fac| fac[:region] == facility }
      [
        index + 1,
        region.name,
        facility.name,
        facility.source.facility_type,
        facility.source.block,
        facility.source.blood_pressures.any? ? "Active" : "Inactive",
        nil,
        matching_facility.dig(:cumulative_registrations, period),
        patients.excluding_dead.count,
        matching_facility.dig(:ltfu_counts, period),
        patients.status_dead.count,
        patients.excluding_dead.not_ltfu_as_of(period.end).count,
        registration_numbers,
        follow_up_numbers,
        matching_facility.dig(:controlled_patients, period),
        matching_facility.dig(:uncontrolled_patients, period),
        matching_facility.dig(:missed_visits, period),
        matching_facility.dig(:visited_without_bp_taken, period),
        Array.new(3, nil)
      ].flatten
    end
  end

  def populate_region_data(region)
    slug = region.slug
    region_data = Hash.new(0)
    region_data[:region] = region
    region_data[:controlled_patients] = repo.controlled_patients_count[slug]
    region_data[:uncontrolled_patients] = repo.uncontrolled_patients_count[slug]
    region_data[:missed_visits] = repo.missed_visits[slug]
    region_data[:cumulative_registrations] = repo.cumulative_registrations[slug]
    region_data[:ltfu_counts] = repo.ltfu_counts[slug]
    region_data[:visited_without_bp_taken] = repo.visited_without_bp_taken[slug]
    region_data
  end
end
