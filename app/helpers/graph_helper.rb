module GraphHelper
  def column_height_styles(value, max_value:, max_height:)
    height = max_value != 0 ? value * max_height / max_value : 0
    "height: #{height}px; margin-top: #{max_height - height}px;"
  end
end
