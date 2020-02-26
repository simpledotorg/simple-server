module NavHelper
  def active_controller?(*controllers)
    "active" if controllers.include?(params[:controller])
  end

  def active_action?(*actions)
    "active" if actions.include?(params[:action])
  end
end
