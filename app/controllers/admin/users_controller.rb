class Admin::UsersController < AdminController
  include Pagination
  include SearchHelper

  before_action :set_user, except: [:index]
  around_action :set_time_zone, only: [:show]
  before_action :set_district, only: [:index]

  skip_after_action :verify_authorized, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  skip_after_action :verify_policy_scoped, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  after_action :verify_authorization_attempted, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }

  def index
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      authorize1 { current_admin.accessible_users.any? }

      facilities = if @district == "All"
        current_admin.accessible_facilities(:manage)
      else
        current_admin.accessible_facilities(:manage).where(district: @district)
      end

      users = current_admin.accessible_users
        .joins(phone_number_authentications: :facility)
        .where(phone_number_authentications: {registration_facility_id: facilities})
        .order("users.full_name", "facilities.name", "users.device_created_at")
    else
      authorize([:manage, :user, User])

      facilities = if @district == "All"
        policy_scope([:manage, :user, Facility.all])
      else
        policy_scope([:manage, :user, Facility.where(district: @district)])
      end

      users = policy_scope([:manage, :user, User])
        .joins(phone_number_authentications: :facility)
        .where("phone_number_authentications.registration_facility_id IN (?)", facilities.map(&:id))
        .order("users.full_name", "facilities.name", "users.device_created_at")
    end

    @users =
      if searching?
        paginate(users.search_by_name_or_phone(search_query))
      else
        paginate(users)
      end
  end

  def show
    @recent_blood_pressures = @user
      .blood_pressures
      .includes(:patient, :facility)
      .order(Arel.sql("DATE(recorded_at) DESC, recorded_at ASC"))

    @recent_blood_pressures = paginate(@recent_blood_pressures)
  end

  def edit
    @user.teleconsultation_isd_code ||= Rails.application.config.country["sms_country_code"]
  end

  def update
    if @user.update_with_phone_number_authentication(user_params)
      redirect_to admin_user_url(@user), notice: "User was successfully updated."
    else
      render :edit
    end
  end

  def reset_otp
    phone_number_authentication = @user.phone_number_authentication
    phone_number_authentication.set_otp
    phone_number_authentication.save

    RequestOtpSmsJob.perform_later(@user)
    redirect_to admin_user_url(@user), notice: "User OTP has been reset."
  end

  def disable_access
    reason_for_denial =
      I18n.t("admin.denied_access_to_user", admin_name: current_admin.email.split("@").first) + "; " +
      params[:reason_for_denial].to_s

    @user.sync_approval_denied(reason_for_denial)
    @user.save
    redirect_to request.referer || admin_user_url(@user), notice: "User access has been disabled."
  end

  def enable_access
    @user.sync_approval_allowed(
      I18n.t("admin.allowed_access_to_user", admin_name: current_admin.email.split("@").first)
    )
    @user.save
    redirect_to request.referer || admin_user_url(@user), notice: "User access has been enabled."
  end

  private

  def ordered_sync_approval_statuses
    {requested: 0, denied: 1, allowed: 2}.with_indifferent_access
  end

  def set_user
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      @user = authorize1 { current_admin.accessible_users.find(params[:id] || params[:user_id]) }
    else
      @user = User.find(params[:id] || params[:user_id])
      authorize([:manage, :user, @user])
    end
  end

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || AnalyticsController::DEFAULT_ANALYTICS_TIME_ZONE
    Time.use_zone(time_zone) { yield }
  end

  def user_params
    params.require(:user).permit(
      :full_name,
      :phone_number,
      :teleconsultation_phone_number,
      :teleconsultation_isd_code,
      :password,
      :password_confirmation,
      :sync_approval_status,
      :registration_facility_id
    )
  end

  def set_district
    @district = params[:district].present? ? params[:district] : "All"
  end
end
