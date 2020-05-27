class CountryConfig
  CONFIGS = {
    IN: {
      abbreviation: "IN",
      name: "India",
      dashboard_locale: ENV["DEFAULT_PREFERRED_DASHBOARD_LOCALE"] || "en_IN",
      time_zone: ENV["DEFAULT_TIME_ZONE"] || "Asia/Kolkata",
      faker_locale: "en-IND",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+91",
      supported_genders: %w[male female transgender]
    },
    BD: {
      abbreviation: "BD",
      name: "Bangladesh",
      dashboard_locale: ENV["DEFAULT_PREFERRED_DASHBOARD_LOCALE"] || "en_BD",
      time_zone: ENV["DEFAULT_TIME_ZONE"] || "Asia/Dhaka",
      faker_locale: "en-IND",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+880",
      supported_genders: %w[male female transgender]
    },
    ET: {
      abbreviation: "ET",
      name: "Ethiopia",
      dashboard_locale: ENV["DEFAULT_PREFERRED_DASHBOARD_LOCALE"] || "en_ET",
      faker_locale: "en-IND",
      time_zone: ENV["DEFAULT_TIME_ZONE"] || "Africa/Addis_Ababa",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+251",
      supported_genders: %w[male female]
    },
    US: {
      abbreviation: "US",
      name: "United States",
      dashboard_locale: "en",
      faker_locale: "en-IND",
      time_zone: "America/New_York",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+1",
      supported_genders: %w[male female transgender]
    },
    UK: {
      abbreviation: "UK",
      name: "United Kingdom",
      dashboard_locale: "en",
      faker_locale: "en-IND",
      time_zone: "Europe/London",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+44",
      supported_genders: %w[male female transgender]
    }
  }.with_indifferent_access.freeze

  def self.for(abbreviation)
    CONFIGS[abbreviation]
  end
end

Rails.application.config.country = CountryConfig.for(ENV.fetch("DEFAULT_COUNTRY"))
