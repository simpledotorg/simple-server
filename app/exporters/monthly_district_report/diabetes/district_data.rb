class MonthlyDistrictReport::Diabetes::DistrictData
  include MonthlyDistrictReport::Utils
  attr_reader :repo, :district, :report_month, :last_6_months

  def initialize(district, period_month)
    @district = district
    @report_month = period_month
    @last_6_months = Range.new(@report_month.advance(months: -5), @report_month)
    @repo = Reports::Repository.new(district, periods: @last_6_months)
  end

  def content_rows
    [row_data]
  end

  def header_rows
    [[ # row 1
      "District",
      "Facilities implementing IHCI",
      "Total DHs/SDHs",
      "Total CHCs",
      "Total PHCs",
      "Total HWCs/SCs",
      "Total diabetes registrations",
      "Total assigned diabetes patients",
      "Total diabetes patients under care",
      "Diabetes treatment outcome", *Array.new(4, nil),
      "Total registered diabetes patients", *Array.new(5, nil),
      "Diabetes patients under care", *Array.new(5, nil),
      "New diabetes registrations (DH/SDH/CHC)", *Array.new(5, nil),
      "New diabetes registrations (PHC)", *Array.new(5, nil),
      "New diabetes registrations (HWC/SC)", *Array.new(5, nil),
      "Diabetes patient follow-ups", *Array.new(5, nil),
      "Blood sugar below 200 rate", *Array.new(5, nil),
      "Blood sugar below 200 count", *Array.new(5, nil),
      "Blood sugar 200 to 300 rate", *Array.new(5, nil),
      "Blood sugar 200 to 300 count", *Array.new(5, nil),
      "Blood sugar over 300 rate", *Array.new(5, nil),
      "Blood sugar over 300 count", *Array.new(5, nil),
      "Cumulative diabetes registrations at HWCs", *Array.new(2, nil),
      "Cumulative diabetes patients under care at HWCs", *Array.new(2, nil),
      "% of assigned diabetes patients at HWCs / SCs (as against district)", *Array.new(2, nil),
      "% of diabetes patients followed up at HWCs / SCs", *Array.new(2, nil),
      "Cumulative assigned diabetes patients to HWCs", * Array.new(2, nil)
    ],
      [ # row 2
        nil, # "District",
        nil, # "Facilities implementing IHCI",
        nil, # "Total DHs/SDHs",
        nil, # "Total CHCs",
        nil, # "Total PHCs",
        nil, # "Total HWCs/SCs",
        nil, # "Total registrations",
        nil, # "Total assigned patients",
        nil, # "Total patients under care",
        "% Blood Sugar Below 200",
        "% Blood Sugar between 200 and 300",
        "% Blood Sugar Over 300",
        "% Missed Visits",
        "% Visits, no blood sugar taken",
        *last_6_months.map { |period| format_period(period) }, # "Total registered patients",
        *last_6_months.map { |period| format_period(period) }, # "Patients under care",
        *last_6_months.map { |period| format_period(period) }, # "New registrations (DH/SDH/CHC)",
        *last_6_months.map { |period| format_period(period) }, # "New registrations (PHC)",
        *last_6_months.map { |period| format_period(period) }, # "New registrations (HWC/SC)",
        *last_6_months.map { |period| format_period(period) }, # "Patient follow-ups",
        *last_6_months.map { |period| format_period(period) }, # "Blood sugar below 200 rate",
        *last_6_months.map { |period| format_period(period) }, # "Blood sugar below 200 count",
        *last_6_months.map { |period| format_period(period) }, # "Blood sugar 200 to 300 rate",
        *last_6_months.map { |period| format_period(period) }, # "Blood sugar 200 to 300 count",
        *last_6_months.map { |period| format_period(period) }, # "Blood sugar over 300 rate",
        *last_6_months.map { |period| format_period(period) }, # "Blood sugar over 300 count",

        *last_6_months.drop(3).map { |period| format_period(period) }, # "Cumulative diabetes registrations at HWCs"
        *last_6_months.drop(3).map { |period| format_period(period) }, # "Cumulative diabetes patients under care at HWCs"
        *last_6_months.drop(3).map { |period| format_period(period) }, # "% of assigned diabetes patients at HWCs / SCs (as against district)"
        *last_6_months.drop(3).map { |period| format_period(period) }, # "% of diabetes patients followed up at HWCs / SCs"
        *last_6_months.drop(3).map { |period| format_period(period) } # "Cumulative assigned diabetess patients to HWCs"
      ]]
  end

  private

  def row_data
    active_facilities = district.facilities.active(month_date: @report_month.to_date)
    facility_counts_by_size = active_facilities.group(:facility_size).count
    {
      "District" => district.name, # "District"
      "Facilities implementing IHCI" => active_facilities.count, # "Facilities implementing IHCI"
      "Total DHs/SDHs" => facility_counts_by_size.fetch("large", 0), # "Total DHs/SDHs"
      "Total CHCs" => facility_counts_by_size.fetch("medium", 0), # "Total CHCs"
      "Total PHCs" => facility_counts_by_size.fetch("small", 0), # "Total PHCs"
      "Total HWCs/SCs" => facility_counts_by_size.fetch("community", 0), # "Total HWCs/SCs"
      "Total diabetes registrations" => repo.cumulative_diabetes_registrations[district.slug][report_month], # "Total diabetes registrations"
      "Total assigned diabetes patients" => repo.cumulative_assigned_diabetic_patients[district.slug][report_month], # "Total diabetes assigned patients"
      "Total diabetes patients under care" => repo.diabetes_under_care[district.slug][report_month], # "Total diabetes patients under care"
      "% Blood Sugar Below 200" => percentage_string(repo.bs_below_200_rates[district.slug][report_month]), # "% BS <200",
      "% Blood Sugar between 200 and 300" => percentage_string(repo.bs_200_to_300_rates[district.slug][report_month]), # "% 200 <= BS < 300",
      "% Blood Sugar Over 300" => percentage_string(repo.bs_over_300_rates[district.slug][report_month]), # "% BS >=300",
      "% Missed Visits" => percentage_string(repo.diabetes_missed_visits_rates[district.slug][report_month]), # "% Missed Visits",
      "% Visits, no blood sugar taken" => percentage_string(repo.visited_without_bs_taken_rates[district.slug][report_month]), # "% Visits, no Blood sugar taken",
      **last_6_months_data(repo.cumulative_diabetes_registrations, :cumulative_diabetes_registrations), # "Total registered diabetes patients",
      **last_6_months_data(repo.diabetes_under_care, :diabetes_under_care), # "Patients under care",
      **last_6_months_data(indicator_by_facility_size([:large, :medium], :monthly_diabetes_registrations), :monthly_diabetes_registrations_large_medium), # "New registrations (DH/SDH/CHC)"
      **last_6_months_data(indicator_by_facility_size([:small], :monthly_diabetes_registrations), :monthly_diabetes_registrations_small), # "New registrations (PHC)"
      **last_6_months_data(indicator_by_facility_size([:community], :monthly_diabetes_registrations), :monthly_diabetes_registrations_community), # "New registrations (HWC/SC)"
      **last_6_months_data(repo.diabetes_follow_ups, :diabetes_follow_ups), # "Patient follow-ups",
      **last_6_months_data(repo.bs_below_200_rates, :bs_below_200_rates, true), # "Blood sugar below 200 rate"
      **last_6_months_data(repo.bs_below_200_patients, :bs_below_200_patients), # "Blood sugar below 200 count",
      **last_6_months_data(repo.bs_200_to_300_rates, :bs_200_to_300_rates, true), # "Blood sugar 200 to 300 rate"
      **last_6_months_data(repo.bs_200_to_300_patients, :bs_200_to_300_patients), # "Blood sugar 200 to 300 count",
      **last_6_months_data(repo.bs_over_300_rates, :bs_over_300_rates, true), # "Blood sugar over 300 rate"
      **last_6_months_data(repo.bs_over_300_patients, :bs_over_300_patients), # "Blood sugar over 300 count"

      # last 3 months of data, at community facilities
      **last_6_months_data(indicator_by_facility_size([:community], :cumulative_diabetes_registrations, last_6_months),
        :cumulative_diabetes_registrations_community).drop(3).to_h, # "Cumulative registrations at HWCs"
      **last_6_months_data(indicator_by_facility_size([:community], :diabetes_under_care, last_6_months),
        :cumulative_diabetes_under_care_community).drop(3).to_h, # "Cumulative patients under care at HWCs"
      **last_6_months_percentage(indicator_by_facility_size([:community], :cumulative_assigned_diabetic_patients, last_6_months.drop(3)),
        repo.cumulative_assigned_diabetic_patients,
        :cumulative_assigned_diabetes_patients_community_percentage)
        .drop(3).to_h, # "% of assigned patients at HWCs / SCs (as against district)"
      **last_6_months_percentage(indicator_by_facility_size([:community], :monthly_diabetes_follow_ups, last_6_months.drop(3)),
        indicator_by_facility_size([:community, :small, :medium, :large], :monthly_diabetes_follow_ups, last_6_months.drop(3)),
        :monthly_diabetes_follow_ups_community_percentage)
        .drop(3).to_h, # "% of patients followed up at HWCs / SCs"
      **last_6_months_data(indicator_by_facility_size([:community], :cumulative_assigned_diabetic_patients, last_6_months.drop(3)),
        :cumulative_assigned_diabetes_patients_community).drop(3).to_h # "Cumulative assigned patients to HWCs"
    }
  end

  def indicator_by_facility_size(facility_sizes, indicator, periods = last_6_months)
    {
      district.slug => Reports::FacilityState
        .where(district_region_id: district.id, month_date: periods, facility_size: facility_sizes)
        .group(:month_date)
        .sum(indicator)
        .map { |k, v| [Period.month(k), v.to_i] }
        .to_h
    }
  end

  def last_6_months_data(data, indicator, show_as_rate = false)
    last_6_months.each_with_object({}) do |month, hsh|
      value = data.dig(district.slug, month) || 0
      hsh["#{indicator} - #{month}"] = indicator_string(value, show_as_rate)
    end
  end

  def last_6_months_percentage(numerators, denominators, indicator)
    last_6_months.each_with_object({}) do |month, hsh|
      value = percentage(numerators.dig(district.slug, month), denominators.dig(district.slug, month))
      hsh["#{indicator} - #{month}"] = indicator_string(value, true)
    end
  end
end
