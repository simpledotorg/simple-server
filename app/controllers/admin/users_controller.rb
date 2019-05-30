class Admin::UsersController < AdminController
  before_action :set_user, except: [:index, :new, :create]

  def index
    authorize MasterUser
    @users_by_district = {}
    policy_scope(Facility).group_by(&:district).each do |district, facilities|
      @users_by_district[district] = facilities.map(&:users).flatten.sort_by do |user|
        [ordered_sync_approval_statuses[user.sync_approval_status], user.full_name]
      end
    end
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to [:admin, @user], notice: 'User was successfully updated.'
    else
      render :edit
    end
  end

  def reset_otp
    @user.set_otp
    @user.save
    SmsNotificationService.new(@user.phone_number).send_request_otp_sms(@user.otp)
    redirect_to [:admin, @user], notice: 'User OTP has been reset.'
  end

  def disable_access
    reason_for_denial =
      I18n.t('admin.denied_access_to_user', admin_name: current_admin.email.split('@').first) + "; " +
      params[:reason_for_denial].to_s

    @user.sync_approval_denied(reason_for_denial)
    @user.save
    redirect_to request.referer || [:admin, @user], notice: 'User access has been disabled.'
  end

  def enable_access
    @user.sync_approval_allowed(I18n.t('admin.allowed_access_to_user', admin_name: current_admin.email.split('@').first))
    @user.save
    redirect_to request.referer || [:admin, @user], notice: 'User access has been enabled.'
  end

  private

  def ordered_sync_approval_statuses
    { requested: 0, denied: 1, allowed: 2 }.with_indifferent_access
  end

  def set_user
    @user = MasterUser.find(params[:id] || params[:user_id])
    authorize @user
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
