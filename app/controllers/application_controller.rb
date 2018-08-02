class ApplicationController < ActionController::Base
  include Pundit

  protect_from_forgery with: :exception

  # Tell pundit how to find the current user
  def pundit_user
    current_admin
  end
end
