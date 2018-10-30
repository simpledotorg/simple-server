module DashboardHelper
  def lighten_if_zero(value)
    value&.positive? ? value : content_tag(:span, value, class: "zero")
  end
end
