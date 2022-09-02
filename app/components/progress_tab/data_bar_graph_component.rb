class ProgressTab::DataBarGraphComponent < ApplicationComponent
  include MyFacilitiesHelper
  attr_reader :rates
  attr_reader :period_info
  attr_reader :data_type

  def initialize(rates:, period_info:, data_type:, graph_css_color:, show_tooltip:)
    @rates = rates
    @period_info = period_info
    @data_type = data_type
  end
end
