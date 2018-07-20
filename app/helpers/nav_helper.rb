module NavHelper
  def active_controller?(controller)
    "active" if params[:controller] == controller
  end
end
