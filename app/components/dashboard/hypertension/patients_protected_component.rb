class Dashboard::Hypertension::PatientsProtectedComponent < ApplicationComponent
  attr_reader :data, :contactable, :period, :period_start

  def initialize(region:, data:, period:)
    @region = region
    @data = data
    # Show only data upto last month
    @period = period.advance(months: -1)
    @period_start = period.advance(months: -36)
  end

  def graph_data
    patients_protected = fill_empty_period_data(:controlled_patients)
    {
      patientsProtected: patients_protected,
      patientsProtectedWithSuffix: patients_protected.map { |k, v| [k, "#{v} patients"] }.to_h
    }
  end

  private

  def fill_empty_period_data(key)
    period_range = (period_start..period)
    period_range.each_with_object(Hash.new(0)) do |period, info|
      info[period] = data[key].fetch(period, 0)
    end
  end
end
