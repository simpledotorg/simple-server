class Dashboard::Hypertension::MeasurementChildComparisonTableComponent < ApplicationComponent
  include DashboardHelper

  attr_reader :data, :children_data, :region, :period, :localized_region_type

  def initialize(data:, children_data:, region:, period:, localized_region_type:)
    @data = data
    @children_data = children_data
    @region = region
    @period = period
    @localized_region_type = localized_region_type
  end

  def row_data(region_data)
    {
      registrations: {
        cumulative: region_data.dig(:cumulative_registrations, period),
        current_month: region_data.dig(:registrations, period)
      },
      controlled: {
        percent: region_data.dig(:controlled_patients_rate, period),
        total: region_data.dig(:controlled_patients, @period)
      },
      uncontrolled: {
        percent: region_data.dig(:uncontrolled_patients_rate, @period),
        total: region_data.dig(:uncontrolled_patients, @period),
      },
      missed_visits: {
        percent: region_data.dig(:missed_visits_rate, @period),
        total: region_data.dig(:missed_visits, @period)
      }
    }
  end
end
