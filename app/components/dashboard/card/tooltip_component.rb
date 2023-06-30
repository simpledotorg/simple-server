class Dashboard::Card::TooltipComponent < ApplicationComponent
  attr_reader :definitions

  def initialize(definitions)
    @definitions = definitions
  end

  def render?
    definitions.present?
  end

  def display_label(label, style)
    return content_tag(:strong, label) unless style
    content_tag(style, label)
  end

  def display_description(description, style)
    return description unless style

    if style == :ul
      content_tag :ul do
        description.split(", ").collect do |item|
          content_tag(:li, item)
        end.join.html_safe
      end
    else
      content_tag(style, description)
    end
  end

  def display_definition(definition)
    content_tag :p, class: "mb-4px" do
      styled_label = display_label(definition[:label], definition[:label_style])
      return styled_label unless definition[:description]

      styled_description = display_description(definition[:description], definition[:description_style])
      styled_label << ": " << styled_description
    end
  end

  def display_footnote(footnote)
    content_tag(:p, class: "mb-4px") do
      content_tag(:i, footnote)
    end
  end

  def display_divider(enable = false)
    return "" unless enable

    tag(:hr, class: "bg-white o-65 mt-4px mb-4px")
  end

  def tooltip_content
    return definitions.to_s if definitions.nil? || (definitions.is_a? String)

    definitions.collect do |definition|
      display_definition(definition) <<
        display_footnote(definition[:footnote]) <<
        display_divider(definition[:enable_divider])
    end.join
  end
end
