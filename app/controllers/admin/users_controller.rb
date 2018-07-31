class Admin::UsersController < ApplicationController
  before_action :set_facility
  before_action :set_user, except: [:index, :new, :create]

  def index
    @users = @facility.users
  end

  def show
  end

  def new
    @user = @facility.users.new
  end

  def edit
  end

  def create
    @user = @facility.users.new(user_params)

    if @user.save
      SmsNotificationService.new(@user).notify
      redirect_to [:admin, @facility], notice: 'User was successfully created.'
    else
      render :new
    end
  end

  def update
    if @user.update(user_params)
      redirect_to [:admin, @facility], notice: 'User was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to [:admin, @facility], notice: 'User was successfully deleted.'
  end

  def reset_otp
    @user.set_otp
    @user.save
    SmsNotificationService.new(@user).notify
    redirect_to [:admin, @facility], notice: 'User otp has been reset.'
  end

  def disable_access
    @user.disable_access
    @user.save
    redirect_to [:admin, @facility], notice: 'User access has been disabled.'
  end

  def enable_access
    @user.enable_access
    @user.save
    SmsNotificationService.new(@user).notify
    redirect_to [:admin, @facility], notice: 'User access has been enabled.'
  end

  private

  def set_facility
    @facility = Facility.find(params[:facility_id])
  end

  def set_user
    @user = User.find(params[:id] || params[:user_id])
  end

  def user_params
    params.require(:user).permit(
      :full_name,
      :phone_number,
      :password,
      :password_confirmation,
      :status
    )
  end
end
