country_config = {
  'IN': {
    abbreviation: 'IN',
    name: 'India',
    dashboard_locale: ENV['DEFAULT_PREFERRED_DASHBOARD_LOCALE'] || 'en_IN',
    time_zone: ENV['DEFAULT_TIME_ZONE'] || 'Asia/Kolkata',
    faker_locale: 'en-IND',
    sms_country_code: ENV['SMS_COUNTRY_CODE'] || '+91',
    supported_genders: %w[male female transgender]
  },
  'BD': {
    abbreviation: 'BD',
    name: 'Bangladesh',
    dashboard_locale: ENV['DEFAULT_PREFERRED_DASHBOARD_LOCALE'] || 'en_BD',
    time_zone: ENV['DEFAULT_TIME_ZONE'] || 'Asia/Dhaka',
    faker_locale: 'en-IND',
    sms_country_code: ENV['SMS_COUNTRY_CODE'] || '+880',
    supported_genders: %w[male female transgender]
  },
  'ET': {
    abbreviation: 'ET',
    name: 'Ethiopia',
    dashboard_locale: ENV['DEFAULT_PREFERRED_DASHBOARD_LOCALE'] || 'en_ET',
    faker_locale: 'en-IND',
    time_zone: ENV['DEFAULT_TIME_ZONE'] || 'Africa/Addis_Ababa',
    sms_country_code: ENV['SMS_COUNTRY_CODE'] || '+251',
    supported_genders: %w[male female]
  }
}.with_indifferent_access

Rails.application.config.country = country_config[ENV.fetch('DEFAULT_COUNTRY')]
