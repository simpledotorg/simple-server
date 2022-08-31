class Dashboard::Hypertension::OverduePatientsContactedTableComponent < ApplicationComponent
  include DashboardHelper

  attr_reader :region, :period, :repository

  def initialize(region:, period:, repository:)
    @region = region
    @period = period
    @repository = repository
  end

  def range
    repository.periods
  end

end
