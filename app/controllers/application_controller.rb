class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :switch_locale

  def switch_locale(&action)
    locale = http_accept_language.language_region_compatible_from(I18n.available_locales) || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def set_reporting_time_zone
    reporting_time_zone = Period::REPORTING_TIME_ZONE

    Groupdate.time_zone = reporting_time_zone
    Time.use_zone(reporting_time_zone) { yield }
  ensure
    Groupdate.time_zone = "UTC"
  end

  def current_enabled_features
    @current_enabled_features ||= Flipper.features.select { |feature| feature.enabled?(current_admin) }.map(&:name)
  end
  helper_method :current_enabled_features

  private

  # Send a user to the admins index after sending invitations
  def after_invite_path_for(inviter, invitee)
    admins_path
  end

  # Used to detect whether the device is mobile/desktop
  def detect_device
    @is_desktop = DeviceDetector.new(request.user_agent).device_type == "desktop"
  end

  # Customize which fields Devise allows for Admins
  # See https://github.com/plataformatec/devise/tree/v3.5.2#strong-parameters
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite, keys: [:email, :role])
  end

  # Use Prosopite to avoid adding n+1 active record queries
  unless Rails.env.production?
    around_action :n_plus_one_detection

    def n_plus_one_detection
      Prosopite.scan
      yield
    ensure
      Prosopite.finish
    end
  end
end
