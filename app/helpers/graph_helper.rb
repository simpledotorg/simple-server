# frozen_string_literal: true

module GraphHelper
  def column_height_styles(value, max_value:, max_height:)
    height = max_value != 0 ? value * max_height / max_value : 0
    "height: #{height}px;"
  end

  def latest_months(data, number_of_months)
    latest_month = data.keys.max
    earliest_month = (latest_month - number_of_months.months).at_beginning_of_month
    data.select { |month, _| month > earliest_month }
      .map { |month, no_of_patients| [month.strftime("%b"), no_of_patients] }
      .to_h
  end
end
