country_config = {
  'IN': {
    abbreviation: 'IN',
    name: 'India',
    dashboard_locale: ENV['DEFAULT_PREFERRED_DASHBOARD_LOCALE'] || 'en_IN',
    time_zone: ENV['DEFAULT_TIME_ZONE'] || 'Asia/Kolkata',
    faker_locale: 'en-IND'
  },
  'BD': {
    abbreviation: 'BD',
    name: 'Bangladesh',
    dashboard_locale: ENV['DEFAULT_PREFERRED_DASHBOARD_LOCALE'] || 'en_BD',
    time_zone: ENV['DEFAULT_TIME_ZONE'] || 'Asia/Dhaka',
    faker_locale: 'en-IND'
  }
}.with_indifferent_access

Rails.application.config.country = country_config[ENV.fetch('DEFAULT_COUNTRY')]
