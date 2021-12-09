class MonthlyDistrictDataService
  attr_reader :region, :period, :months, :repo, :dashboard_analytics
  def initialize(region, period)
    @region = region
    @period = period
    @months = period.downto(5).reverse
    regions = region.facility_regions.to_a << region
    @repo = Reports::Repository.new(regions, periods: @months)
    @dashboard_analytics = DistrictAnalyticsQuery.new(region, :month, 6, period.value, include_current_period: true).call
  end

  def report
    CSV.generate(headers: true) do |csv|
      csv << ["Monthly Facility Data: #{region.name} #{period.to_date.strftime("%B %Y")}"]
      csv << section_labels
      csv << header_row
      csv << district_row
      facility_rows.each do |row|
        csv << row
      end
    end
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
      Array.new(4, nil),
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
      "Estimated hypertensive population",
      "Total registrations",
      "Total assigned patients",
      "Lost to follow-up patients",
      "Dead patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})",
      "Patients under care as of #{period.end.strftime("%e-%b-%Y")}",
      month_labels,
      month_labels,
      "Patients under care as of #{period.adjusted_period.end.strftime("%e-%b-%Y")}",
      "Patients with BP controlled",
      "Patients with BP not controlled",
      "Patients with a missed visit",
      "Patients with a visit but no BP taken",
      "Amlodipine",
      "ARBs/ACE Inhibitors",
      "Diuretic"
    ].flatten
  end

  def district_row
    follow_ups_by_month = months.each_with_object({}) { |month, hsh|
      monthly_count = dashboard_analytics.sum { |_, data| data.dig(:follow_up_patients_by_period, month.value) || 0 }
      hsh["follow_ups_#{month.value}".to_sym] = monthly_count
    }
    region_data = {
      serial_number: "All",
      district_name: region.name,
      facility_name: nil,
      facility_type: nil,
      block_name: nil,
      active: nil
    }.merge(common_attributes(region, follow_ups_by_month))
    region_data.values
  end

  def facility_rows
    region.facility_regions.map.with_index do |facility, index|
      follow_ups_by_month = months.each_with_object({}) { |month, hsh|
        monthly_count = dashboard_analytics.dig(facility.source.id, :follow_up_patients_by_period, month.value) || 0
        hsh["follow_ups_#{month.value}".to_sym] = monthly_count
      }

      facility_data = {
        serial_number: index + 1,
        district_name: region.name,
        facility_name: facility.name,
        facility_type: facility.source.facility_type,
        block_name: facility.source.block,
        active: facility.source.blood_pressures.any? ? "Active" : "Inactive"
      }.merge(common_attributes(facility, follow_ups_by_month))
      facility_data.values
    end
  end

  def common_attributes(region, follow_ups_by_month)
    complete_monthly_registrations = repo.monthly_registrations[region.slug]
    registered_by_month = months.each_with_object({}) { |month, hsh|
      hsh["registrations_#{month.value}".to_sym] = (complete_monthly_registrations[month] || 0)
    }

    dead_count = region.assigned_patients.with_hypertension.status_dead.count
    assigned_patients_count = repo.cumulative_assigned_patients.dig(region.slug, period) || 0
    ltfu_count = repo.ltfu.dig(region.slug, period) || 0
    patients_under_care = assigned_patients_count - ltfu_count
    controlled_count = repo.controlled.dig(region.slug, period) || 0
    uncontrolled_count = repo.uncontrolled.dig(region.slug, period) || 0
    missed_visits = repo.missed_visits.dig(region.slug, period) || 0
    no_bp_taken = repo.visited_without_bp_taken.dig(region.slug, period) || 0
    adjusted_patients_under_care = repo.adjusted_patients.dig(region.slug, period) || 0

    {
      estimated_hypertension_population: nil,
      total_registrations: repo.cumulative_registrations.dig(region.slug, period) || 0,
      total_assigned: assigned_patients_count,
      ltfu: ltfu_count,
      dead: dead_count,
      patients_under_care: patients_under_care,
      **registered_by_month,
      **follow_ups_by_month,
      adjusted_patients_under_care: adjusted_patients_under_care,
      controlled_count: controlled_count,
      uncontrolled_count: uncontrolled_count,
      missed_visits: missed_visits,
      no_bp_taken: no_bp_taken,
      amlodipine: nil,
      arbs_and_ace_inhibitors: nil,
      diurectic: nil
    }
  end
end
