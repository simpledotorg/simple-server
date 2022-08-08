class Dashboard::Diabetes::CoverageCardComponent < ApplicationComponent
  attr_reader :region
  attr_reader :data
  attr_reader :period
  attr_reader :current_admin

  def initialize(region:, data:, period:, current_admin:)
    @region = region
    @data = data
    @period = period
    @current_admin = current_admin
  end
end
