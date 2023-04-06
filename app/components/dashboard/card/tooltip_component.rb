class Dashboard::Card::TooltipComponent < ApplicationComponent
  attr_reader :definitions

  def initialize(definitions)
    @definitions = definitions
  end

  def render?
    definitions.present?
  end

  def tooltip_content
    return definitions.to_s if !definitions.is_a? Hash
    definitions.collect do |name, description|
      content_tag :p, class: "mb-4px" do
        if name != "Note"
          content_tag(:strong, name) << ": #{description}"
        else
          content_tag(:i, description)
        end
      end
    end.join
  end
end
