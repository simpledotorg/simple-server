module MonthlyDistrictReport
  class DistrictData
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
          *last_6_months.map(&:to_s), # "Total registered patients",
          *last_6_months.map(&:to_s), # "Patients under care",
          *last_6_months.map(&:to_s), # "New registrations (DH/SDH/CHC)",
          *last_6_months.map(&:to_s), # "New registrations (PHC)",
          *last_6_months.map(&:to_s), # "New registrations (HWC/SC)",
          *last_6_months.map(&:to_s), # "Patient follow-ups",
          *last_6_months.map(&:to_s), # "BP controlled rate"
          *last_6_months.map(&:to_s), # "BP controlled count"

          *last_6_months.drop(3).map(&:to_s), # "Cumulative registrations at HWCs"
          *last_6_months.drop(3).map(&:to_s), # "Cumulative patients under care at HWCs"
          *last_6_months.drop(3).map(&:to_s), # "% of assigned patients at HWCs / SCs (as against district)"
          *last_6_months.drop(3).map(&:to_s), # "% of patients followed up at HWCs / SCs"
          *last_6_months.drop(3).map(&:to_s) # "Cumulative assigned patients to HWCs"
        ]]
    end

    private

    def row_data
      facility_counts_by_size = district.facilities.group(:facility_size).count
      {
        "District" => district.name,
        "Facilities implementing IHCI" => district.facilities.count,
        "Total DHs/SDHs" => facility_counts_by_size.fetch("large", 0),
        "Total CHCs" => facility_counts_by_size.fetch("medium", 0),
        "Total PHCs" => facility_counts_by_size.fetch("small", 0),
        "Total HWCs/SCs" => facility_counts_by_size.fetch("community", 0),
        "Total registrations" => repo.cumulative_registrations[district.slug][report_month],
        "Total assigned patients" => repo.cumulative_assigned_patients[district.slug][report_month],
        "Total patients under care" => repo.under_care[district.slug][report_month],
        "% BP controlled" => repo.controlled_rates[district.slug][report_month],
        "% BP uncontrolled" => repo.uncontrolled_rates[district.slug][report_month],
        "% Missed Visits" => repo.missed_visits_rate[district.slug][report_month],
        "% Visits, no BP taken" => repo.visited_without_bp_taken_rates[district.slug][report_month],
        **last_6_months_data(repo.cumulative_registrations, :cumulative_registrations), # "Total registered patients",
        **last_6_months_data(repo.under_care, :under_care), # "Patients under care",
        **last_6_months_data({}, :something_1), # TODO: **last_6_months_data(repo.monthly_registrations, district, :monthly_registrations), # "New registrations (DH/SDH/CHC)",
        **last_6_months_data({}, :something_2), # TODO: **last_6_months_data(repo.monthly_registrations, district, :monthly_registrations), # "New registrations (PHC)",
        **last_6_months_data({}, :something_3), # TODO: **last_6_months_data(repo.monthly_registrations, district, :monthly_registrations), # "New registrations (HWC/SC)",
        **last_6_months_data(repo.hypertension_follow_ups, :hypertension_follow_ups), # "Patient follow-ups",
        **last_6_months_data(repo.controlled_rates, :controlled_rates), # "BP controlled rate"
        **last_6_months_data(repo.controlled, :controlled), # "BP controlled count"

        **last_6_months_data({}, :something_4).drop(3).to_h, # TODO: *last_6_months.drop(3).map(&:to_s), # "Cumulative registrations at HWCs"
        **last_6_months_data({}, :something_5).drop(3).to_h, # TODO: *last_6_months.drop(3).map(&:to_s), # "Cumulative patients under care at HWCs"
        **last_6_months_data({}, :something_6).drop(3).to_h, # TODO: *last_6_months.drop(3).map(&:to_s), # "% of assigned patients at HWCs / SCs (as against district)"
        **last_6_months_data({}, :something_7).drop(3).to_h, # TODO: *last_6_months.drop(3).map(&:to_s), # "% of patients followed up at HWCs / SCs"
        **last_6_months_data({}, :something_8).drop(3).to_h # TODO: *last_6_months.drop(3).map(&:to_s), # "Cumulative assigned patients to HWCs"
      }
    end

    def last_6_months_data(data, indicator)
      last_6_months.each_with_object({}) do |month, hsh|
        hsh["#{indicator} - #{month}"] = data.dig(district.slug, month)
      end
    end
  end
end
