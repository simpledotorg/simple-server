# frozen_string_literal: true

module PhoneNumberLocalizable
  extend ActiveSupport::Concern

  included do
    def localized_phone_number
      parsed_number = Phonelib.parse(phone_number, Rails.application.config.country[:abbreviation]).raw_national
      country_code = Rails.application.config.country[:sms_country_code]
      country_code + parsed_number
    end
  end
end
