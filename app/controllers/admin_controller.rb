class AdminController < ApplicationController
  before_action :authenticate_email_authentication!
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  rescue_from ActiveRecord::RecordInvalid do
    head :bad_request
  end

  rescue_from ActionController::ParameterMissing do
    head :bad_request
  end

  def switch_locale(&action)
    locale =
      ENV['DEFAULT_PREFERRED_DASHBOARD_LOCALE'].presence ||
        http_accept_language.compatible_language_from(I18n.available_locales) ||
        I18n.default_locale

    I18n.with_locale(locale, &action)
  end

  helper_method :current_admin

  private

  def current_admin
    current_email_authentication.user
  end

  def pundit_user
    current_admin
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
