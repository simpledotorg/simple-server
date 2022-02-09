class MedicationDispensationService
  MONTHS = -2

  def self.call(*args)
    new(*args).call
  end

  def initialize(region:, period:)
    @region = region
    @period = period
    @range = (@period.advance(months: MONTHS)..@period)
  end

  def call
    repo = Reports::Repository.new(@region, periods: @range)
    {
      "0-14 days" => {color: "#BD3838",
                      counts: repo.appts_scheduled_0_to_14_days[@region.slug],
                      totals: repo.total_appts_scheduled[@region.slug],
                      percentages: repo.appts_scheduled_0_to_14_days_rates[@region.slug]},
      "1 month (15-31 days)" => {color: "#E77D27",
                                 counts: repo.appts_scheduled_15_to_31_days[@region.slug],
                                 totals: repo.total_appts_scheduled[@region.slug],
                                 percentages: repo.appts_scheduled_15_to_31_days_rates[@region.slug]},
      "2 months (32-62 days)" => {color: "#729C26",
                                  counts: repo.appts_scheduled_32_to_62_days[@region.slug],
                                  totals: repo.total_appts_scheduled[@region.slug],
                                  percentages: repo.appts_scheduled_32_to_62_days_rates[@region.slug]},
      ">2 months" => {color: "#007AA6",
                      counts: repo.appts_scheduled_more_than_62_days[@region.slug],
                      totals: repo.total_appts_scheduled[@region.slug],
                      percentages: repo.appts_scheduled_more_than_62_days_rates[@region.slug]}
    }
  end
end
