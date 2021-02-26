class EmailAuthentications::PasswordValidationsController < ApplicationController
  def create
    auth = EmailAuthentication.new(password: params[:password])
    auth.validate
    render json: {errors: auth.errors[:password]}
  end
end
