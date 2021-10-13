module PhoneNumberHelpers
  def localize_phone_number(number, country_code)
    if country_code
      country_code + number
    else
      parsed_number = Phonelib.parse(number, Rails.application.config.country[:abbreviation]).raw_national
      default_country_code = Rails.application.config.country[:sms_country_code]
      default_country_code + parsed_number
    end
  end
end