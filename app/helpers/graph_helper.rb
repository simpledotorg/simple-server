module GraphHelper
  def column_height_styles(value, max_value:, max_height:)
    height = max_value != 0 ? value * max_height / max_value : 0
    "height: #{height}px;"
  end

  def week_label(from_date_string, to_date_string)
    content_tag('div', class: 'graph-label') do
      concat(content_tag('div', from_date_string, class: 'label-1'))
      concat(content_tag('div', to_date_string, class: 'label-1'))
    end
  end
end
