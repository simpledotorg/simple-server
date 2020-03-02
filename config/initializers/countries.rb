country_config = {
  'IN': {
    abbreviation: 'IN',
    name: 'India',
    dashboard_locale: ENV['DEFAULT_PREFERRED_DASHBOARD_LOCALE'] || 'en_IN',
    time_zone: ENV['DEFAULT_TIME_ZONE'] || 'Asia/Kolkata',
    sms_country_code: ENV['SMS_COUNTRY_CODE'] || '+91'
  },
  'BD': {
    abbreviation: 'BD',
    name: 'Bangladesh',
    dashboard_locale: ENV['DEFAULT_PREFERRED_DASHBOARD_LOCALE'] || 'en_BD',
    time_zone: ENV['DEFAULT_TIME_ZONE'] || 'Asia/Dhaka',
    sms_country_code: ENV['SMS_COUNTRY_CODE'] || '+880'
  }
}.with_indifferent_access

Rails.application.config.country = country_config[ENV.fetch('DEFAULT_COUNTRY')]
