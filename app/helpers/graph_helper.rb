module GraphHelper
  def column_height_styles(value, max_value:, max_height:)
    height = max_value != 0 ? value * max_height / max_value : 0
    "height: #{height}px;"
  end

  def label_for_week(week, current_week)
    return graph_label('This week', '') if week == current_week
    start_date = start_of_week(week)
    end_date = end_of_week(start_date)
    graph_label(start_date.strftime('%b %e'), 'to ' + end_date.strftime('%b %e'))
  end

  def graph_label(label_1, label_2)
    content_tag('div', class: 'graph-label') do
      concat(content_tag('div', label_1, class: 'label-1'))
      concat(content_tag('div', label_2, class: 'label-1'))
    end
  end

  def start_of_week(date)
    date.at_beginning_of_week(start_date = :sunday)
  end

  def end_of_week(date)
    date.at_end_of_week(start_date = :sunday)
  end

  def format_statistics_for_view(stats, current_week)
    stats.map { |k, v| [k, { label: label_for_week(k, current_week), value: v }] }
  end
end
