module NavHelper
  def active_controller?(*controllers)
    "active" if controllers.include?(params[:controller])
  end
end
