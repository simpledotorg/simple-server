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
    @user.otp = user_otp
    @user.otp_valid_until = user_otp_valid_until


    if @user.save
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

  def user_otp
    digits = (0..9).to_a
    otp = ''
    6.times do
      otp += digits.sample.to_s
    end
    otp
  end

  def user_otp_valid_until
    Time.now + ENV['USER_OTP_VALID_UNTIL_DELTA_IN_MINUTESS'].to_i.minutes
  end
end
