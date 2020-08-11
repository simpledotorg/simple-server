class CohortService
  attr_reader :region, :quarters

  def initialize(region:, quarters: nil)
    @region = region
    @quarters = quarters || default_quarters
  end

  # Each quarter cohort is made up of patients registered in the previous quarter
  # who has had a follow up visit in the current quarter.
  def totals
    result = {quarterly_registrations: []}
    quarters.each do |results_quarter|
      cohort_quarter = results_quarter.previous_quarter

      period = {cohort_period: :quarter,
                registration_quarter: cohort_quarter.number,
                registration_year: cohort_quarter.year}
      query = MyFacilities::BloodPressureControlQuery.new(facilities: region.facilities, cohort_period: period)
      result[:quarterly_registrations] << {
        results_in: format_quarter(results_quarter),
        patients_registered: format_quarter(cohort_quarter),
        registered: query.cohort_registrations.count,
        controlled: query.cohort_controlled_bps.count,
        no_bp: query.cohort_missed_visits_count,
        uncontrolled: query.cohort_uncontrolled_bps.count
      }.with_indifferent_access
    end
    result
  end

  def format_quarter(quarter)
    "Q#{quarter.number} #{quarter.year}"
  end

  def default_quarters
    Quarter.new(date: Date.current).downto(3)
  end
end
