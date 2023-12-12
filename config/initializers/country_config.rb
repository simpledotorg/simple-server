class CountryConfig
  COUNTRYWISE_STATES = YAML.load_file("config/data/canonical_states.yml")

  CONFIGS = {
    IN: {
      abbreviation: "IN",
      name: "India",
      extended_region_reports: true,
      states: COUNTRYWISE_STATES["India"],
      dashboard_locale: ENV["DEFAULT_PREFERRED_DASHBOARD_LOCALE"] || "en-IN",
      time_zone: ENV["DEFAULT_TIME_ZONE"] || "Asia/Kolkata",
      faker_locale: "en-IND",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+91",
      supported_genders: %w[male female transgender],
      patient_line_list_show_zone: false,
      custom_drug_category_order: %w[hypertension_ccb hypertension_arb hypertension_diuretic diabetes],
      appointment_reminders_channel: "Messaging::Bsnl::Sms"
    },
    BD: {
      abbreviation: "BD",
      name: "Bangladesh",
      extended_region_reports: true,
      states: COUNTRYWISE_STATES["Bangladesh"],
      dashboard_locale: ENV["DEFAULT_PREFERRED_DASHBOARD_LOCALE"] || "en-BD",
      time_zone: ENV["DEFAULT_TIME_ZONE"] || "Asia/Dhaka",
      faker_locale: "en-IND",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+880",
      supported_genders: %w[male female transgender],
      patient_line_list_show_zone: true,
      enabled_diabetes_population_coverage: true,
      appointment_reminders_channel: "Messaging::AlphaSms::Sms"
    },
    ET: {
      abbreviation: "ET",
      name: "Ethiopia",
      extended_region_reports: true,
      states: COUNTRYWISE_STATES["Ethiopia"],
      dashboard_locale: ENV["DEFAULT_PREFERRED_DASHBOARD_LOCALE"] || "en-ET",
      faker_locale: "en-IND",
      time_zone: ENV["DEFAULT_TIME_ZONE"] || "Africa/Addis_Ababa",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+251",
      supported_genders: %w[male female],
      patient_line_list_show_zone: false,
      appointment_reminders_channel: "Messaging::Twilio::ReminderSms"
    },
    LK: {
      abbreviation: "LK",
      name: "Sri Lanka",
      extended_region_reports: false,
      states: COUNTRYWISE_STATES["Sri Lanka"],
      dashboard_locale: ENV["DEFAULT_PREFERRED_DASHBOARD_LOCALE"] || "en-LK",
      faker_locale: "en-IND",
      time_zone: ENV["DEFAULT_TIME_ZONE"] || "Asia/Colombo",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+94",
      supported_genders: %w[male female],
      patient_line_list_show_zone: false,
      appointment_reminders_channel: "Messaging::Twilio::ReminderSms"
    },
    US: {
      abbreviation: "US",
      name: "United States",
      extended_region_reports: true,
      dashboard_locale: "en",
      faker_locale: "en-IND",
      time_zone: "America/New_York",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+1",
      supported_genders: %w[male female transgender],
      patient_line_list_show_zone: false,
      appointment_reminders_channel: "Messaging::Twilio::ReminderSms"
    },
    UK: {
      abbreviation: "UK",
      name: "United Kingdom",
      extended_region_reports: true,
      dashboard_locale: "en",
      faker_locale: "en-IND",
      time_zone: "Europe/London",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+44",
      supported_genders: %w[male female transgender],
      patient_line_list_show_zone: false,
      appointment_reminders_channel: "Messaging::Twilio::ReminderSms"
    }
  }.with_indifferent_access.freeze

  class << self
    def dhis2_data_elements
      YAML.load_file("config/data/dhis2/sandbox.yml").with_indifferent_access
    end
  end

  def self.for(abbreviation)
    CONFIGS[abbreviation]
  end

  def self.current
    Rails.application.config.country
  end

  def self.country_environment_file
    ".env.#{current[:abbreviation]}"
  end

  def self.current_country?(country)
    CountryConfig.current[:name] == country
  end
end

Rails.application.config.country = CountryConfig.for(ENV.fetch("DEFAULT_COUNTRY"))
Dotenv.overload(CountryConfig.country_environment_file)
