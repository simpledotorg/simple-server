class Dashboard::Card::LtfuToggleComponent < ApplicationComponent
  attr_reader :id
  attr_reader :enabled


  def initialize(id:, enabled:)
    @id = id
    @enabled = enabled
  end
end
