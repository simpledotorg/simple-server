class Dashboard::MedicationDispensationComponent < ApplicationComponent
  attr_reader :data
  attr_reader :region
  attr_reader :period

  def initialize(data:, region:, period:)
    @data = data
    @region = region
    @period = period
  end

  def graph_data
    data[:medications_dispensation]
  end
end
