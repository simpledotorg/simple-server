class Reports::RepositoryCacheWarmer
  def self.call(args)
    new(args).call
  end

  attr_reader :region
  attr_reader :repository

  def initialize(region:, period:)
    @region = region
    @period = period
    @range = period.advance(months: -23)
    @repository = Reports::Repository.new(region, periods: @range)
  end

  # We are only caching things that _are not_ called via the RegionService for right now.
  # As we move away from RegionService, we can add more things to be explicitly cached here.
  def call
    repository.missed_visits
    repository.missed_visits_rate
    if region.facility_region?
      repository.hypertension_follow_ups(group_by: "blood_pressures.user_id")
    else
      repository.hypertension_follow_ups
    end
  end
end
