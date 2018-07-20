class AdminController < ApplicationController
  before_action :authenticate_admin!
  after_action :verify_authorized

  # Tell pundit how to find the current user
  def pundit_user
    current_admin
  end
end
