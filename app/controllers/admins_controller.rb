class AdminsController < AdminController
  include Pagination
  include SearchHelper

  before_action :set_admin, only: [:show, :edit, :update, :resend_invitation, :access_tree, :destroy]
  before_action :verify_params, only: [:update]

  def index
    admins = current_admin.accessible_admins(:manage)
    authorize { admins.any? }

    @admins =
      if searching?
        paginate(admins.search_by_name_or_email(search_query))
      else
        paginate(admins.order("email_authentications.email"))
      end
  end

  def access_tree
    access_tree =
      case page_for_access_tree
      when :show
        AdminAccessPresenter.new(@admin).visible_access_tree
      when :new, :edit
        AdminAccessPresenter.new(current_admin).visible_access_tree
      else
        head(:not_found) && return
      end

    if page_for_access_tree.eql?(:edit)
      user_being_edited = AdminAccessPresenter.new(@admin)
      set_facilities_pre_checks(user_being_edited)
    else
      user_being_edited = nil
    end

    render partial: access_tree[:render_partial],
      locals: {
        tree: access_tree[:data],
        root: access_tree[:root],
        user_being_edited: user_being_edited,
        tree_depth: 0,
        page: page_for_access_tree
      }
  end

  def show
  end

  def edit
  end

  def update
    User.transaction do
      @admin.update!(user_params)
      current_admin.grant_access(@admin, selected_facilities)
    end

    redirect_to admins_url, notice: "Admin was successfully updated."
  end

  def resend_invitation
    admin = authorize { current_admin.accessible_admins(:manage).find_by!(id: params[:id]) }
    email_authentication = admin.email_authentication

    if email_authentication.blank?
      redirect_to admins_url,
        alert: "An invitation couldn't be sent to #{admin.full_name}. Please delete the invited administrator and try again."
    elsif email_authentication.invited_to_sign_up?
      email_authentication.invite!

      redirect_to admins_url, notice: "An invitation was sent again to #{admin.full_name} (#{email_authentication.email})."
    else
      redirect_to admins_url,
        alert: "#{admin.full_name} (#{email_authentication.email}) hasn't been invited, or has already accepted their invitation"
    end
  end

  def destroy
    authorize { current_admin.manage_organization? && current_admin.accessible_admins(:manage).find_by_id(@admin.id) }
    @admin.discard
    redirect_to admins_url, notice: "Admin was successfully deleted."
  end

  private

  def verify_params
    if validate_selected_facilities?
      flash[:alert] = "At least one facility should be selected for access before editing an Admin."
      render :edit, status: :bad_request

      return
    end

    if access_level_changed? && !current_admin.manage_organization?
      raise UserAccess::NotAuthorizedError
    end

    @admin.assign_attributes(user_params)

    if @admin.invalid?
      flash[:alert] = @admin.errors.full_messages.join("")
      render :edit, status: :bad_request
    end
  end

  def set_admin
    @admin = authorize { current_admin.accessible_admins(:manage).find(params[:id]) }
  end

  def selected_facilities
    params[:facilities]
  end

  def user_params
    {
      full_name: params[:full_name],
      role: params[:role],
      organization_id: params[:organization_id],
      access_level: params[:access_level],
      receive_approval_notifications: params[:receive_approval_notifications],
      device_updated_at: Time.current
    }.compact
  end

  def page_for_access_tree
    params[:page].to_sym
  end

  def access_level_changed?
    return false if user_params[:access_level].blank?

    @admin.access_level != user_params[:access_level]
  end

  def validate_selected_facilities?
    selected_facilities.blank? && user_params[:access_level] != User.access_levels[:power_user]
  end

  def set_facilities_pre_checks(user)
    @facilities_pre_checks = user.visible_facilities.map(&:id).product([true]).to_h
  end
end
