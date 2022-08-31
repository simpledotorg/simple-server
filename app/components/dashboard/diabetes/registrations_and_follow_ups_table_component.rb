class Dashboard::Diabetes::RegistrationsAndFollowUpsTableComponent < ApplicationComponent
  include DashboardHelper

  attr_reader :region
  attr_reader :period
  attr_reader :repository

  def initialize(region:, period:, repository:)
    @region = region
    @period = period
    @repository = repository
  end

  def range
    repository.periods
  end

  def row_data(region:)
    [repository.cumulative_diabetes_registrations[region.slug][period],
     repository.cumulative_assigned_diabetic_patients[region.slug][period],
     *range.map { |range_period| repository.monthly_diabetes_registrations[region.slug][range_period] },
     *range.map { |range_period| repository.diabetes_follow_ups[region.slug][range_period] }]
  end
end
