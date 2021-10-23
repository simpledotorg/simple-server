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

  def call
    repository.hypertension_follow_ups
    # see regions/details.html.erb for where these are used
    if region.facility_region?
      repository.bp_measures_by_user
      repository.hypertension_follow_ups(group_by: "blood_pressures.user_id")
      repository.monthly_registrations_by_user
    end
  end
end
