class Dashboard::Card::TitleComponent < ApplicationComponent
  attr_reader :title
  attr_reader :subtitle
  attr_reader :tooltip_definitions

  renders_one :ltfu_toggle, Dashboard::Card::LtfuToggleComponent

  def initialize(title:, subtitle: nil, tooltip_definitions: nil)
    @title = title
    @subtitle = subtitle
    @tooltip_definitions = tooltip_definitions
  end
end
