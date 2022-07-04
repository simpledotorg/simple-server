class Dashboard::Card::TitleComponent < ApplicationComponent
  attr_reader :title
  attr_reader :subtitle
  attr_reader :tooltip_definitions

  def initialize(title:, subtitle: nil, tooltip_definitions: nil)
    @title = title
    @subtitle = subtitle
    @tooltip_definitions = tooltip_definitions
  end
end
