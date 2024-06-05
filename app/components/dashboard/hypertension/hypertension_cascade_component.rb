class Dashboard::Hypertension::HypertensionCascadeComponent < ApplicationComponent
  attr_reader :data, :contactable, :period

  def initialize(region:, data:, period:)
    @region = region
    @data = data
    @period = period
  end

  def graph_data
    {
      **period_data
    }
  end

  private

  def period_data
    {
      startDate: period.advance(months: -17),
      endDate: period_info(:name)
    }
  end

  def period_info(key)
    data[:period_info].map { |k, v| [k, v[key]] }.to_h
  end
end
