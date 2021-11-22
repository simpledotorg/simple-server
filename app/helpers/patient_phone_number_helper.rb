module PatientPhoneNumberHelper
  def number_with_country_code(phone_number)
    parsed_number = Phonelib.parse(phone_number, Rails.application.config.country[:abbreviation]).raw_national
    default_country_code = Rails.application.config.country[:sms_country_code]
    default_country_code + parsed_number
  end
end
