class AdminController < ApplicationController
  before_action :authenticate_email_authentication!

  after_action :verify_authorization_attempted, except: [:root]

  rescue_from UserAccess::NotAuthorizedError, with: :user_not_authorized

  rescue_from ActiveRecord::RecordInvalid do
    head :bad_request
  end

  rescue_from ActionController::ParameterMissing do
    head :bad_request
  end

  def switch_locale(&action)
    locale =
      Rails.application.config.country[:dashboard_locale].presence ||
      http_accept_language.compatible_language_from(I18n.available_locales) ||
      I18n.default_locale

    I18n.with_locale(locale, &action)
  end

  def root
    if current_admin.call_center_access?
      redirect_to appointments_path
    else
      redirect_to my_facilities_overview_path
    end
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

  def authorize(&blk)
    RequestStore.store[:authorization_attempted] = true

    begin
      capture = yield(blk)

      unless capture
        raise UserAccess::NotAuthorizedError
      end

      capture
    rescue ActiveRecord::RecordNotFound
      raise UserAccess::NotAuthorizedError
    end
  end

  def verify_authorization_attempted
    raise UserAccess::AuthorizationNotPerformedError unless RequestStore.store[:authorization_attempted]
  end
end
