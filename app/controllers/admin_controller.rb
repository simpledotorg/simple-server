class AdminController < ApplicationController
  before_action :authenticate_admin!
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  rescue_from ActiveRecord::RecordInvalid do
    head :bad_request
  end

  rescue_from ActionController::ParameterMissing do
    head :bad_request
  end

  helper_method :current_user

  private

  def current_user
    current_admin.user
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
