class Dashboard::Card::GraphComponent < ApplicationComponent
  attr_reader :id
  attr_reader :data
  attr_reader :period

  renders_one :title, Dashboard::Card::TitleComponent
  renders_one :summary
  renders_one :footer


  def initialize(id:, data:, period:)
    @id = id
    @data = data
    @period = period
  end
end
