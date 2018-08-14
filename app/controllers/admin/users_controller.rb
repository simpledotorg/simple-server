class Admin::UsersController < ApplicationController
  before_action :set_user, except: [:index, :new, :create]

  def index
    authorize User
    @users = User.all
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
    SmsNotificationService.new(@user).notify
    redirect_to [:admin, @user], notice: 'User otp has been reset.'
  end

  def disable_access
    authorize @user
    @user.disable_access
    @user.save
    redirect_to [:admin, @user], notice: 'User access has been disabled.'
  end

  def enable_access
    authorize @user
    @user.enable_access
    @user.save
    SmsNotificationService.new(@user).notify
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
