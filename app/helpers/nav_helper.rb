# frozen_string_literal: true

module NavHelper
  def active_controller?(*controllers)
    "active" if controllers.include?(params[:controller])
  end

  def active_action?(*actions)
    "active" if actions.include?(params[:action])
  end

  def active_controller_and_action?(controllers, actions)
    if controllers.include?(params[:controller]) && actions.include?(params[:action])
      "active"
    end
  end
end
