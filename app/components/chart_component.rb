class ChartComponent < ViewComponent::Base
  with_content_areas :header, :summary, :description

  def initialize(data:, chart_type:)
    @data = data
    @chart_type = chart_type
  end

  attr_reader :data
  attr_reader :chart_type

  def percentage_class
    case chart_type
    when :controlled
      "c-green-dark"
    when :uncontrolled
      "c-red"
    else
      raise ArgumentError, "unknonwn chart type #{chart_type}"
    end
  end

  def canvas_id
    case chart_type
    when :controlled
      "controlledPatientsTrend"
    when :uncontrolled
      "uncontrolledPatientsTrend"
    else
      raise ArgumentError, "unknown chart type #{chart_type}"
    end
  end

  def most_recent_value
    data&.values&.last
  end
end
