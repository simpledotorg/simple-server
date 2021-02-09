class AdminController < ApplicationController
  before_action :authenticate_email_authentication!

  after_action :verify_authorization_attempted, except: [:root]

  rescue_from UserAccess::NotAuthorizedError, with: :user_not_authorized

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

  def set_force_cache
    RequestStore.store[:force_cache] = true if force_cache?
  end

  def force_cache?
    params[:force_cache].present?
  end

  helper_method :current_admin

  private

  def current_admin
    return @current_admin if defined?(@current_admin)
    admin = current_email_authentication.user
    admin.email_authentications.load
    @current_admin = admin
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

      unless current_admin.power_user? || capture
        logger.error "authorize error: user does not have access to specified resource(s)"
        raise UserAccess::NotAuthorizedError
      end

      capture
    rescue ActiveRecord::RecordNotFound
      logger.error "authorize error: RecordNotFound raised, turning it into a NotAuthorizedError"
      raise UserAccess::NotAuthorizedError
    end
  end

  def verify_authorization_attempted
    raise UserAccess::AuthorizationNotPerformedError unless RequestStore.store[:authorization_attempted]
  end
end
