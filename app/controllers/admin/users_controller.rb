class Admin::UsersController < AdminController
  include DistrictFiltering
  include Pagination

  before_action :set_user, except: [:index, :new, :create]
  around_action :set_time_zone, only: [:show]

  def index
    authorize([:manage, :user, User])
    @users = policy_scope([:manage, :user, User])
      .joins(phone_number_authentications: :facility)
      .where(
        "phone_number_authentications.registration_facility_id IN (?)",
        selected_district_facilities([:manage, :user]).map(&:id)
      )
      .order("facilities.name", "users.full_name", "users.device_created_at")

    @users = paginate(@users)
  end

  def show
    @recent_blood_pressures = @user
      .blood_pressures
      .includes(:patient, :facility)
      .order(Arel.sql("DATE(recorded_at) DESC, recorded_at ASC"))

    @recent_blood_pressures = paginate(@recent_blood_pressures)
  end

  def edit
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

    SmsNotificationService.new(@user.phone_number, ENV["TWILIO_PHONE_NUMBER"]).send_request_otp_sms(@user.otp)
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
    @user = User.find(params[:id] || params[:user_id])
    authorize([:manage, :user, @user])
  end

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || AnalyticsController::DEFAULT_ANALYTICS_TIME_ZONE
    Time.use_zone(time_zone) { yield }
  end

  def user_params
    params.require(:user).permit(
      :full_name,
      :phone_number,
      :password,
      :password_confirmation,
      :sync_approval_status,
      :registration_facility_id
    )
  end
end
