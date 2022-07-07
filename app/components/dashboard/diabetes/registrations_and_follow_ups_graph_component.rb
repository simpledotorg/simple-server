class Dashboard::Diabetes::RegistrationsAndFollowUpsGraphComponent < ApplicationComponent
  attr_reader :region
  attr_reader :period
  attr_reader :with_ltfu

  def initialize(region:, period:, with_ltfu: false)
    @region = region
    @period = period
    @with_ltfu = with_ltfu
  end

  def denominator_copy
    with_ltfu ? "diabetes_denominator_with_ltfu_copy" : "diabetes_denominator_copy"
  end
end
