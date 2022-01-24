class MedicationDispensationService
  MONTHS = -2

  def initialize(region:, period:)
    @region = region
    @period = period
    @medications_dispensation_range = (@period.advance(months: MONTHS)..@period)
  end

  def distribution
    medications_dispensation_repo = Reports::Repository.new(@region, periods: @medications_dispensation_range)
    {
      "0 - 14 days" => {color: "#BD3838",
                        counts: medications_dispensation_repo.appts_scheduled_0_to_14_days[@region.slug],
                        totals: medications_dispensation_repo.total_appts_scheduled[@region.slug],
                        percentages: medications_dispensation_repo.appts_scheduled_0_to_14_days_rates[@region.slug]},
      "15 - 30 days" => {color: "#E77D27",
                         counts: medications_dispensation_repo.appts_scheduled_15_to_30_days[@region.slug],
                         totals: medications_dispensation_repo.total_appts_scheduled[@region.slug],
                         percentages: medications_dispensation_repo.appts_scheduled_15_to_30_days_rates[@region.slug]},
      "31 - 60 days" => {color: "#729C26",
                         counts: medications_dispensation_repo.appts_scheduled_31_to_60_days[@region.slug],
                         totals: medications_dispensation_repo.total_appts_scheduled[@region.slug],
                         percentages: medications_dispensation_repo.appts_scheduled_31_to_60_days_rates[@region.slug]},
      "60+ days" => {color: "#007AA6",
                     counts: medications_dispensation_repo.appts_scheduled_more_than_60_days[@region.slug],
                     totals: medications_dispensation_repo.total_appts_scheduled[@region.slug],
                     percentages: medications_dispensation_repo.appts_scheduled_more_than_60_days_rates[@region.slug]}
    }
  end
end
