# frozen_string_literal: true

class EmailAuthentications::InvitationsController < Devise::InvitationsController
  include DatadogTagging # need to include here because this does not inherit from any of our base controllers
  before_action :verify_params, only: [:create]
  helper_method :current_admin

  rescue_from UserAccess::NotAuthorizedError, with: :user_not_authorized

  def new
    raise UserAccess::NotAuthorizedError unless current_admin.accessible_facilities(:manage).any?
    super
  end

  def create
    raise UserAccess::NotAuthorizedError unless current_admin.accessible_facilities(:manage).any?

    User.transaction do
      new_user = User.new(user_params)

      super do |resource|
        new_user.email_authentications = [resource]
        new_user.save!

        current_admin.grant_access(new_user, selected_facilities)
      end
    end
  end

  protected

  def verify_params
    user = User.new(user_params)
    password = EmailAuthentication.generate_password
    email_authentication = user.email_authentications.new(invite_params.merge(password: password))

    if validate_selected_facilities?
      flash[:alert] = "At least one facility should be selected for access before inviting an Admin."
      render :new, status: :bad_request

      return
    end

    if user.invalid? || email_authentication.invalid?
      user.errors.delete(:email_authentications)
      flash[:alert] = (user.errors.full_messages + email_authentication.errors.full_messages).join("\n")
      render :new, status: :bad_request
    end
  end

  def current_admin
    AdminAccessPresenter.new(current_inviter.user)
  end

  def pundit_user
    current_admin
  end

  def user_params
    {
      full_name: params[:full_name],
      role: params[:role],
      access_level: params[:access_level],
      organization_id: params[:organization_id],
      receive_approval_notifications: params[:receive_approval_notifications],
      device_created_at: Time.current,
      device_updated_at: Time.current,
      sync_approval_status: :denied
    }
  end

  def selected_facilities
    params[:facilities]
  end

  def permission_params
    params[:permissions]
  end

  def invite_params
    {email: params[:email]}
  end

  def validate_selected_facilities?
    selected_facilities.blank? && user_params[:access_level] != User.access_levels[:power_user]
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
