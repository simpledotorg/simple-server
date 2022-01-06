# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :switch_locale

  def switch_locale(&action)
    locale = http_accept_language.compatible_language_from(I18n.available_locales) || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def set_reporting_time_zone
    reporting_time_zone = Period::REPORTING_TIME_ZONE

    Groupdate.time_zone = reporting_time_zone
    Time.use_zone(reporting_time_zone) { yield }
  ensure
    Groupdate.time_zone = "UTC"
  end

  private

  # Send a user to the admins index after sending invitations
  def after_invite_path_for(inviter, invitee)
    admins_path
  end

  # Customize which fields Devise allows for Admins
  # See https://github.com/plataformatec/devise/tree/v3.5.2#strong-parameters
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite, keys: [:email, :role])
  end
end
