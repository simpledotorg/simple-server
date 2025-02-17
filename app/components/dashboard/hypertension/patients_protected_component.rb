class Dashboard::Hypertension::PatientsProtectedComponent < ApplicationComponent
  attr_reader :period, :period_start

  def initialize(region:, period:)
    @region = region
    # Show only data up to last month
    @period = period.advance(months: -1)
    @period_start = period.advance(months: -36)
    @repo = Reports::Repository.new(@region, periods: Range.new(@period_start, @period))
  end

  def graph_data
    {
      patientsProtected: patients_protected,
      patientsProtectedWithSuffix: patients_protected_with_suffix
    }
  end

  private

  def patients_protected_with_suffix
    patients_protected.transform_values { |v| "#{number_with_delimiter(v, delimiter: ",")} patients" }.to_h
  end

  def patients_protected
    period_range = (period_start..period)
    period_range.each_with_object(Hash.new(0)) do |period, info|
      info[period] = @repo.controlled[@region.slug].fetch(period, 0)
    end
  end
end
