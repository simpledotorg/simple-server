module MonthlyDistrictReport
  class DistrictData
    include Utils
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
        "Total registrations",
        "Total assigned patients",
        "Total patients under care",
        "Treatment outcome", *Array.new(3, nil),
        "Total registered patients", *Array.new(5, nil),
        "Patients under care", *Array.new(5, nil),
        "New registrations (DH/SDH/CHC)", *Array.new(5, nil),
        "New registrations (PHC)", *Array.new(5, nil),
        "New registrations (HWC/SC)", *Array.new(5, nil),
        "Patient follow-ups", *Array.new(5, nil),
        "BP controlled rate", *Array.new(5, nil),
        "BP controlled count", *Array.new(5, nil),
        "Cumulative registrations at HWCs", *Array.new(2, nil),
        "Cumulative patients under care at HWCs", *Array.new(2, nil),
        "% of assigned patients at HWCs / SCs (as against district)", *Array.new(2, nil),
        "% of patients followed up at HWCs / SCs", *Array.new(2, nil),
        "Cumulative assigned patients to HWCs", * Array.new(2, nil)
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
          "% BP controlled",
          "% BP uncontrolled",
          "% Missed Visits",
          "% Visits, no BP taken",
          *last_6_months.map { |period| format_period(period) }, # "Total registered patients",
          *last_6_months.map { |period| format_period(period) }, # "Patients under care",
          *last_6_months.map { |period| format_period(period) }, # "New registrations (DH/SDH/CHC)",
          *last_6_months.map { |period| format_period(period) }, # "New registrations (PHC)",
          *last_6_months.map { |period| format_period(period) }, # "New registrations (HWC/SC)",
          *last_6_months.map { |period| format_period(period) }, # "Patient follow-ups",
          *last_6_months.map { |period| format_period(period) }, # "BP controlled rate"
          *last_6_months.map { |period| format_period(period) }, # "BP controlled count"

          *last_6_months.drop(3).map { |period| format_period(period) }, # "Cumulative registrations at HWCs"
          *last_6_months.drop(3).map { |period| format_period(period) }, # "Cumulative patients under care at HWCs"
          *last_6_months.drop(3).map { |period| format_period(period) }, # "% of assigned patients at HWCs / SCs (as against district)"
          *last_6_months.drop(3).map { |period| format_period(period) }, # "% of patients followed up at HWCs / SCs"
          *last_6_months.drop(3).map { |period| format_period(period) } # "Cumulative assigned patients to HWCs"
        ]]
    end

    private

    def row_data
      facility_counts_by_size = district.facilities.active.group(:facility_size).count
      {
        "District" => district.name, # "District"
        "Facilities implementing IHCI" => district.facilities.active.count, # "Facilities implementing IHCI"
        "Total DHs/SDHs" => facility_counts_by_size.fetch("large", 0), # "Total DHs/SDHs"
        "Total CHCs" => facility_counts_by_size.fetch("medium", 0), # "Total CHCs"
        "Total PHCs" => facility_counts_by_size.fetch("small", 0), # "Total PHCs"
        "Total HWCs/SCs" => facility_counts_by_size.fetch("community", 0), # "Total HWCs/SCs"
        "Total registrations" => repo.cumulative_registrations[district.slug][report_month], # "Total registrations"
        "Total assigned patients" => repo.cumulative_assigned_patients[district.slug][report_month], # "Total assigned patients"
        "Total patients under care" => repo.under_care[district.slug][report_month], # "Total patients under care"
        "% BP controlled" => percentage_string(repo.controlled_rates[district.slug][report_month]), # "% BP controlled",
        "% BP uncontrolled" => percentage_string(repo.uncontrolled_rates[district.slug][report_month]), # "% BP uncontrolled",
        "% Missed Visits" => percentage_string(repo.missed_visits_rate[district.slug][report_month]), # "% Missed Visits",
        "% Visits, no BP taken" => percentage_string(repo.visited_without_bp_taken_rates[district.slug][report_month]), # "% Visits, no BP taken",
        **last_6_months_data(repo.cumulative_registrations, :cumulative_registrations), # "Total registered patients",
        **last_6_months_data(repo.under_care, :under_care), # "Patients under care",
        **last_6_months_data(indicator_by_facility_size([:large, :medium], :monthly_registrations), :monthly_registrations_large_medium), # "New registrations (DH/SDH/CHC)"
        **last_6_months_data(indicator_by_facility_size([:small], :monthly_registrations), :monthly_registrations_small), # "New registrations (PHC)"
        **last_6_months_data(indicator_by_facility_size([:community], :monthly_registrations), :monthly_registrations_community), # "New registrations (HWC/SC)"
        **last_6_months_data(repo.hypertension_follow_ups, :hypertension_follow_ups), # "Patient follow-ups",
        **last_6_months_data(repo.controlled_rates, :controlled_rates, true), # "BP controlled rate"
        **last_6_months_data(repo.controlled, :controlled), # "BP controlled count"

        # last 3 months of data, at community facilities
        **last_6_months_data(indicator_by_facility_size([:community], :cumulative_registrations, last_6_months),
          :cumulative_registrations_community).drop(3).to_h, # "Cumulative registrations at HWCs"
        **last_6_months_data(indicator_by_facility_size([:community], :under_care, last_6_months),
          :cumulative_under_care_community).drop(3).to_h, # "Cumulative patients under care at HWCs"
        **last_6_months_percentage(indicator_by_facility_size([:community], :cumulative_assigned_patients, last_6_months.drop(3)),
          repo.cumulative_assigned_patients,
          :cumulative_assigned_patients_community_percentage)
          .drop(3).to_h, # "% of assigned patients at HWCs / SCs (as against district)"
        **last_6_months_percentage(indicator_by_facility_size([:community], :monthly_follow_ups, last_6_months.drop(3)),
          indicator_by_facility_size([:community, :small, :medium, :large], :monthly_follow_ups, last_6_months.drop(3)),
          :monthly_follow_ups_community_percentage)
          .drop(3).to_h, # "% of patients followed up at HWCs / SCs"
        **last_6_months_data(indicator_by_facility_size([:community], :cumulative_assigned_patients, last_6_months.drop(3)),
          :cumulative_assigned_patients_community).drop(3).to_h # "Cumulative assigned patients to HWCs"
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
end
