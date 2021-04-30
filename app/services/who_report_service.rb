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
      "Estimated hypertension population",
      "Total registrations",
      "Total assigned patients",
      "Patients lost to follow-up",
      "Died",
      "Patients under care",
      month_labels,
      month_labels,
      "Patients with BP controlled",
      "Patients with BP not controlled",
      "Patients with a missed visits",
      "Patients with a visit but no BP taken",
      "Amlodipine",
      "ARBs/ACE Inhibitors",
      "Diuretic"
    ].flatten
  end

  def district_row
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
      repo.cumulative_registrations.dig(region.slug, period) || 0,
      patients.excluding_dead.count,
      repo.ltfu_counts.dig(region.slug, period) || 0,
      patients.status_dead.count,
      patients.excluding_dead.not_ltfu_as_of(period.end).count,
      registered_by_month,
      follow_up_by_month,
      repo.controlled_patients_count.dig(region.slug, period) || 0,
      repo.uncontrolled_patients_count.dig(region.slug, period) || 0,
      repo.missed_visits.dig(region.slug, period) || 0,
      repo.visited_without_bp_taken.dig(region.slug, period) || 0,
      Array.new(3, nil)
    ].flatten
  end

  def facility_rows
    region.facility_regions.map.with_index do |facility, index|
      analytics_data = dashboard_analytics[facility.id]
      registration_numbers = []
      follow_up_numbers = []

      months.each do |month|
        registration_numbers << (dashboard_analytics.dig(facility.source.id, :registered_patients_by_period, month.value) || 0)
        follow_up_numbers << (dashboard_analytics.dig(facility.source.id, :follow_up_patients_by_period, month.value) || 0)
      end
      patients = Patient.with_hypertension.where(assigned_facility: facility.source)

      [
        index + 1,
        region.name,
        facility.name,
        facility.source.facility_type,
        facility.source.block,
        facility.source.blood_pressures.any? ? "Active" : "Inactive",
        nil,
        repo.cumulative_registrations.dig(facility.slug, period) || 0,
        patients.excluding_dead.count,
        repo.ltfu_counts.dig(facility.slug, period) || 0,
        patients.status_dead.count,
        patients.excluding_dead.not_ltfu_as_of(period.end).count,
        registration_numbers,
        follow_up_numbers,
        repo.controlled_patients_count.dig(facility.slug, period) || 0,
        repo.uncontrolled_patients_count.dig(facility.slug, period) || 0,
        repo.missed_visits.dig(facility.slug, period) || 0,
        repo.visited_without_bp_taken.dig(facility.slug, period) || 0,
        Array.new(3, nil)
      ].flatten
    end
  end
end
