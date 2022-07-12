class Dashboard::Card::TableComponent < ApplicationComponent
  attr_reader :id

  renders_many :column_groups

  renders_many :headers, ->(title, colspan: 1, tooltip: nil) do
    content_tag :th, colspan: colspan, class: "sticky nowrap" do
      concat title
      concat render(Dashboard::Card::TooltipComponent.new(tooltip))
    end
  end

  renders_many :sub_headers, ->(title, colspan: 1, sort_method: "number", sort_default: false) do
    data = { sort_method: sort_method }
    data[:sort_default] = true if sort_default
    content_tag :th, colspan: colspan, class: "row-label sort-label sort-label-small ta-left", data: data do
      title + " " # Need the extra space between the text and sort arrow
    end
  end

  renders_many :rows

  def initialize(id:)
    @id = id
  end
end
