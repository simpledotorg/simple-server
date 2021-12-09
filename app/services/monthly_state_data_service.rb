class MonthlyStateDataService
  attr_reader :region, :period, :months, :repo, :dashboard_analytics
  def initialize(region, period)
    @region = region
    @period = period
    @months = period.downto(5).reverse
    regions = region.district_regions.to_a << region
    @repo = Reports::Repository.new(regions, periods: @months)
  end

  def report
    CSV.generate(headers: true) do |csv|
      csv << ["Monthly State Data: #{region.name} #{period.to_date.strftime("%B %Y")}"]
      csv << section_row
      csv << header_row
      csv << parent_row
      child_rows.each do |row|
        csv << row
      end
    end
  end

  private

  def section_row
    [
      # These just add empty spacer columns
      Array.new(9, nil),
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
      "State",
      "District",
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

  def parent_row
    row_data = {
      index: "All",
      parent_name: region.name,
      child_name: nil
    }.merge(region_data(region))

    row_data.values
  end

  def child_rows
    region.children.map.with_index do |child, index|
      row_data = {
        index: index + 1,
        parent_name: region.name,
        child_name: child.name
      }.merge(region_data(region))

      row_data.values
    end
  end

  def region_data(region)
    total_registrations_count = repo.cumulative_registrations.dig(region.slug, period)
    assigned_patients_count = repo.cumulative_assigned_patients.dig(region.slug, period)
    ltfu_count = repo.ltfu.dig(region.slug, period)
    dead_count = region.assigned_patients.with_hypertension.status_dead.count
    adjusted_patients_under_care_count = repo.adjusted_patients.dig(region.slug, period)
    controlled_count = repo.controlled.dig(region.slug, period)
    uncontrolled_count = repo.uncontrolled.dig(region.slug, period)
    missed_visits_count = repo.missed_visits.dig(region.slug, period)
    no_bp_taken_count = repo.visited_without_bp_taken.dig(region.slug, period)

    monthly_registrations = repo.monthly_registrations[region.slug]
    registrations_by_month = months.each_with_object({}) { |month, hsh|
      hsh["registrations_#{month.value}".to_sym] = monthly_registrations[month]
    }

    monthly_follow_ups = repo.hypertension_follow_ups[region.slug]
    follow_ups_by_month = months.each_with_object({}) { |month, hsh|
      hsh["follow_ups_#{month.value}".to_sym] = monthly_follow_ups[month] || 0
    }

    {
      estimated_hypertension_population: nil,
      total_registrations: total_registrations_count,
      total_assigned: assigned_patients_count,
      ltfu: ltfu_count,
      dead: dead_count,
      patients_under_care: assigned_patients_count - ltfu_count,
      **registrations_by_month,
      **follow_ups_by_month,
      adjusted_patients_under_care: adjusted_patients_under_care_count,
      controlled_count: controlled_count,
      uncontrolled_count: uncontrolled_count,
      missed_visits: missed_visits_count,
      no_bp_taken: no_bp_taken_count,
      amlodipine: nil,
      arbs_and_ace_inhibitors: nil,
      diurectic: nil
    }
  end
end
