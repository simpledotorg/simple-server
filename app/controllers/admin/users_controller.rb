class Admin::UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :set_facilities, only: %i[create edit update new]

  def index
    @users = User.all
  end

  def show
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)

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
    redirect_to admin_users_url, notice: 'User was successfully destroyed.'
  end

  def reset_otp
    user = User.find(params[:user_id])
    user.set_otp
    user.save
    SmsNotificationService.new(user).notify
    redirect_to admin_users_url, notice: 'User otp has been reset.'
  end

  def disable_access
    user = User.find(params[:user_id])
    user.disable_access
    user.save
    redirect_to admin_users_url, notice: 'User access has been disabled.'
  end

  def enable_access
    user = User.find(params[:user_id])
    user.enable_access
    user.save
    SmsNotificationService.new(user).notify
    redirect_to admin_users_url, notice: 'User access has been enabled.'
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :full_name, 
      :phone_number,
      :password,
      :password_confirmation,
      :facility_id
    )
  end

  def set_facilities
    @facilities = Facility.all
  end
end
