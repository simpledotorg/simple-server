class Admin::UsersController < AdminController
  before_action :set_user, except: [:index, :new, :create]

  def ordered_sync_approval_statuses
    { requested: 0, denied: 1, allowed: 2 }.with_indifferent_access
  end

  def index
    authorize User
    @users = User.all.sort_by do |user|
      [ordered_sync_approval_statuses[user.sync_approval_status],
       user.updated_at]
    end
  end

  def show
    @current_admin = current_admin
  end

  def new
    @user = User.new
    authorize @user
  end

  def edit
  end

  def create
    @user = User.new(user_params)
    authorize @user

    if @user.save
      SmsNotificationService.new(@user).notify
      redirect_to [:admin, @user], notice: 'User was successfully created.'
    else
      render :new
    end
  end

  def update
    if @user.update(user_params)
      redirect_to [:admin, @user], notice: 'User was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to [:admin, :users], notice: 'User was successfully deleted.'
  end

  def reset_otp
    @user.set_otp
    @user.save
    SmsNotificationService.new(@user).send_request_otp_sms
    redirect_to [:admin, @user], notice: 'User otp has been reset.'
  end

  def disable_access
    @user.sync_approval_denied(I18n.t('admin.denied_access_to_user', admin_name: @current_admin.email.split('@').first))
    @user.save
    redirect_to [:admin, @user], notice: 'User access has been disabled.'
  end

  def enable_access
    @user.sync_approval_allowed(I18n.t('admin.allowed_access_to_user', admin_name: @current_admin.email.split('@').first))
    @user.save
    redirect_to [:admin, @user], notice: 'User access has been enabled.'
  end

  private

  def set_user
    @user = User.find(params[:id] || params[:user_id])
    authorize @user
  end

  def user_params
    params.require(:user).permit(
      :full_name,
      :phone_number,
      :password,
      :password_confirmation,
      :sync_approval_status,
      facility_ids: []
    )
  end
end
