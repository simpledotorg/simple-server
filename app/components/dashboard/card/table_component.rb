class Dashboard::Card::TableComponent < ApplicationComponent
  attr_reader :id

  renders_many :column_groups

  renders_many :headers, ->(title, colspan: 1, tooltip: nil) do
    content_tag :th, colspan: colspan, class: "sticky nowrap" do
      concat title
      concat render(Dashboard::Card::TooltipComponent.new(tooltip))
    end
  end

  renders_many :sub_headers, ->(title, colspan: 1, sort_method: 'number', sort_default: false) do
    content_tag :th, colspan: colspan, class: "row-label sort-label sort-label-small ta-left", data: {
      sort_default: sort_default,
      sort_method: sort_method
    } do
      title
    end
  end

  renders_many :rows

  def initialize(id:)
    @id = id
  end
end
