class AdminController < ApplicationController
  before_action :authenticate_email_authentication!

  after_action :verify_authorized, except: [:root]
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
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
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      redirect_to access_root_paths
    else
      redirect_to default_root_paths.find { |policy, _path|
        DashboardPolicy.new(pundit_user, :dashboard).send(policy)
      }.second
    end
  end

  helper_method :current_admin

  private

  def default_root_paths
    {
      view_my_facilities?: my_facilities_overview_path,
      show?: organizations_path,
      overdue_list?: appointments_path,
      manage_organizations?: admin_organizations_path,
      manage_facilities?: admin_facilities_path,
      manage_protocols?: admin_protocols_path,
      manage_admins?: admins_path,
      manage_users?: admin_users_path
    }
  end

  def access_root_paths
    if current_admin.call_center_access?
      appointments_path
    else
      my_facilities_overview_path
    end
  end

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

  def authorize1(&blk)
    RequestStore.store[:authorization_attempted] = true

    begin
      capture = yield(blk)

      unless capture
        raise UserAccess::NotAuthorizedError, self.class
      end

      capture
    rescue
      raise UserAccess::NotAuthorizedError, self.class
    end
  end

  def verify_access_authorized
    raise UserAccess::AuthorizationNotPerformedError, self.class unless RequestStore.store[:authorization_attempted]
  end
end
