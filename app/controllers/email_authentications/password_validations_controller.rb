# frozen_string_literal: true

class EmailAuthentications::PasswordValidationsController < ApplicationController
  def create
    auth = EmailAuthentication.new(password: params[:password])
    auth.validate
    errors = auth.errors.details[:password].collect { |e| e[:error] }
    render json: {errors: errors}
  end
end
