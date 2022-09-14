class ProgressTab::CohortReportsComponent < ApplicationComponent
  attr_reader :data

  def initialize(data:)
    @data = data
  end
end
