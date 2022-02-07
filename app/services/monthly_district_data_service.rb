class MonthlyDistrictDataService
  attr_reader :region, :period, :months, :repo, :dashboard_analytics
  def initialize(region, period)
    @region = region
    @period = period
    @months = period.downto(5).reverse
    @medication_dispensation_months = period.downto(2).reverse
    regions = region.facility_regions.to_a << region
    @repo = Reports::Repository.new(regions, periods: @months)
  end

  def report
    CSV.generate(headers: true) do |csv|
      csv << ["Monthly #{localized_facility} data for #{region.name} #{period.to_date.strftime("%B %Y")}"]
      csv << section_row
      csv << sub_section_row
      csv << header_row
      csv << district_row

      csv << [] # Empty row
      facility_size_rows.each do |row|
        csv << row
      end

      csv << [] # Empty row
      facility_rows.each do |row|
        csv << row
      end
    end
  end

  private

  def localized_district
    I18n.t("region_type.district")
  end

  def localized_block
    I18n.t("region_type.block")
  end

  def localized_facility
    I18n.t("region_type.facility")
  end

  def region_headers
    [
      "#",
      localized_block.capitalize,
      localized_facility.capitalize,
      "#{localized_facility.capitalize} type",
      "#{localized_facility.capitalize} size"
    ]
  end

  def summary_headers
    [
      "Estimated hypertensive population",
      "Total registrations",
      "Total assigned patients",
      "Lost to follow-up patients",
      "Dead patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})",
      "Patients under care as of #{period.end.strftime("%e-%b-%Y")}"
    ]
  end

  def month_headers
    months.map { |month| month.value.strftime("%b-%Y") }
  end

  def outcome_headers
    [
      "Patients under care as of #{period.adjusted_period.end.strftime("%e-%b-%Y")}",
      "Patients with BP controlled",
      "Patients with BP not controlled",
      "Patients with a missed visit",
      "Patients with a visit but no BP taken"
    ]
  end

  def medications_dispensation_headers
    [
      "Patients with 0 to 14 days of medications",
      "Patients with 15 to 31 days of medications",
      "Patients with 32 to 62 days of medications",
      "Patients with 62+ days of medications"
    ]
  end

  def medications_dispensation_month_headers
    @medication_dispensation_months.map { |month| month.to_s }
  end

  def drug_headers
    [
      "Amlodipine",
      "ARBs/ACE Inhibitors",
      "Diuretic"
    ]
  end

  def section_row
    [
      # These just add empty spacer columns
      Array.new(region_headers.size + summary_headers.size, nil),
      "New Registrations",
      Array.new(month_headers.size - 1, nil),
      "Follow-up patients",
      Array.new(month_headers.size - 1, nil),
      "Treatment outcomes of patients under care",
      Array.new(outcome_headers.size - 1, nil),
      "Days of patient medications",
      Array.new((medications_dispensation_headers.size * 3) - 1, nil),
      "Drug availability",
      Array.new(drug_headers.size - 1, nil)
    ].flatten
  end

  def sub_section_row
    [
      Array.new(region_headers.size + summary_headers.size + month_headers.size * 2 + outcome_headers.size, nil),
      medications_dispensation_month_headers.first,
      Array.new(medications_dispensation_headers.size - 1, nil),
      medications_dispensation_month_headers.second,
      Array.new(medications_dispensation_headers.size - 1, nil),
      medications_dispensation_month_headers.last
    ].flatten
  end

  def header_row
    [
      region_headers,
      summary_headers,
      month_headers,
      month_headers,
      outcome_headers,
      medications_dispensation_headers,
      medications_dispensation_headers,
      medications_dispensation_headers,
      drug_headers
    ].flatten
  end

  def district_row
    row_data = {
      index: "All #{localized_facility.pluralize}",
      block: nil,
      facility: nil,
      facility_type: nil,
      facility_size: "All"
    }.merge(region_data(region))

    row_data.values
  end

  def facility_size_rows
    size_data = Hash.new { |hash, key| hash[key] = {} }

    region.facility_regions.sort_by { |f| [f.block_region.name, f.name] }.map.with_index do |facility, index|
      facility_data = region_data(facility)

      # Sum each data key for all facilities in this size
      size_data[facility.source.facility_size].update(facility_data) do |key, old_value, new_value|
        old_value.nil? ? new_value : old_value + new_value
      end
    end

    size_data.sort.map do |size, summed_data|
      row_data = {
        index: "#{size.capitalize} #{localized_facility.pluralize}",
        block: nil,
        facility: nil,
        facility_type: nil,
        facility_size: size.capitalize
      }.merge(summed_data)

      row_data.values
    end
  end

  def facility_rows
    region.facility_regions.sort_by { |f| [f.block_region.name, f.name] }.map.with_index do |facility, index|
      row_data = {
        index: index + 1,
        block: facility.block_region.name,
        facility: facility.name,
        facility_type: facility.source.facility_type,
        facility_size: facility.source.facility_size.capitalize
      }.merge(region_data(facility))

      row_data.values
    end
  end

  def region_data(subregion)
    total_registrations_count = repo.cumulative_registrations.dig(subregion.slug, period)
    assigned_patients_count = repo.cumulative_assigned_patients.dig(subregion.slug, period)
    ltfu_count = repo.ltfu.dig(subregion.slug, period)
    dead_count = subregion.assigned_patients.with_hypertension.status_dead.count
    adjusted_patients_under_care_count = repo.adjusted_patients.dig(subregion.slug, period)
    controlled_count = repo.controlled.dig(subregion.slug, period)
    uncontrolled_count = repo.uncontrolled.dig(subregion.slug, period)
    missed_visits_count = repo.missed_visits.dig(subregion.slug, period)
    no_bp_taken_count = repo.visited_without_bp_taken.dig(subregion.slug, period)

    monthly_registrations = repo.monthly_registrations[subregion.slug]
    registrations_by_month = months.each_with_object({}) { |month, hsh|
      hsh["registrations_#{month.value}".to_sym] = monthly_registrations[month]
    }

    monthly_follow_ups = repo.hypertension_follow_ups[subregion.slug]
    follow_ups_by_month = months.each_with_object({}) { |month, hsh|
      hsh["follow_ups_#{month.value}".to_sym] = monthly_follow_ups[month] || 0
    }

    medications_dispensation_by_month = period.downto(2).reverse.each_with_object({}) { |month, hsh|
      hsh["Patients_with_0_to_14_days_of_medications_#{month}".to_sym] = repo.appts_scheduled_0_to_14_days[subregion.slug][month]
      hsh["Patients_with_15_to_31_days_of_medications_#{month}".to_sym] = repo.appts_scheduled_15_to_31_days[subregion.slug][month]
      hsh["Patients_with_32_to_62_days_of_medications_#{month}".to_sym] = repo.appts_scheduled_32_to_62_days[subregion.slug][month]
      hsh["Patients_with_62+_days_of_medications_#{month}".to_sym] = repo.appts_scheduled_more_than_62_days[subregion.slug][month]
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
      **medications_dispensation_by_month,
      amlodipine: nil,
      arbs_and_ace_inhibitors: nil,
      diurectic: nil
    }
  end
end
