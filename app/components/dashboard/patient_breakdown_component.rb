class Dashboard::PatientBreakdownComponent < ApplicationComponent
  attr_reader :region, :data, :period, :tooltips

  def initialize(region:, data:, period:, tooltips:)
    @region = region
    @data = data
    @period = period
    @tooltips = tooltips
  end
end
