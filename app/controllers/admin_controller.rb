class AdminController < ApplicationController
  before_action :authenticate_admin!
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  rescue_from ActionController::ParameterMissing do
    render nothing: true, status: :bad_request
  end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
