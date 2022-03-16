class CountryConfig
  COUNTRYWISE_STATES = YAML.load_file("config/data/canonical_states.yml")

  CONFIGS = {
    IN: {
      abbreviation: "IN",
      name: "India",
      extended_region_reports: true,
      states: COUNTRYWISE_STATES["India"],
      dashboard_locale: ENV["DEFAULT_PREFERRED_DASHBOARD_LOCALE"] || "en_IN",
      time_zone: ENV["DEFAULT_TIME_ZONE"] || "Asia/Kolkata",
      faker_locale: "en-IND",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+91",
      supported_genders: %w[male female transgender],
      patient_line_list_show_zone: false,
      custom_drug_category_order: %w[hypertension_ccb hypertension_arb hypertension_diuretic],
      maharashtra_dhis2_data_elements: {
        monthly_registrations_male: "F0cPY1T9lNs.tY82VK3LTQq",
        monthly_registrations_female: "F0cPY1T9lNs.VHbljVQ8REF",
        controlled_male: "FSuHsnyPYcV.tY82VK3LTQq",
        controlled_female: "FSuHsnyPYcV.VHbljVQ8REF"
      },
      appointment_reminders_channel: Messaging::Twilio::Sms
    },
    BD: {
      abbreviation: "BD",
      name: "Bangladesh",
      extended_region_reports: true,
      states: COUNTRYWISE_STATES["Bangladesh"],
      dashboard_locale: ENV["DEFAULT_PREFERRED_DASHBOARD_LOCALE"] || "en_BD",
      time_zone: ENV["DEFAULT_TIME_ZONE"] || "Asia/Dhaka",
      faker_locale: "en-IND",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+880",
      supported_genders: %w[male female transgender],
      patient_line_list_show_zone: true,
      dhis2_data_elements: {
        cumulative_assigned: "cc2oSjEbiqv",
        cumulative_assigned_adjusted: "jQBsCW7wjqx",
        controlled: "ItViYyHGgZf",
        uncontrolled: "IH0SueuKSWe",
        missed_visits: "N7rI9y9Kywp",
        ltfu: "nso1TSN7ukq",
        dead: "Qf8Wq8u6AkK",
        cumulative_registrations: "BK2KRHKcTtU",
        monthly_registrations: "GxLDDKPxjxx"
      },
      appointment_reminders_channel: Messaging::Twilio::Sms
    },
    ET: {
      abbreviation: "ET",
      name: "Ethiopia",
      extended_region_reports: true,
      states: COUNTRYWISE_STATES["Ethiopia"],
      dashboard_locale: ENV["DEFAULT_PREFERRED_DASHBOARD_LOCALE"] || "en_ET",
      faker_locale: "en-IND",
      time_zone: ENV["DEFAULT_TIME_ZONE"] || "Africa/Addis_Ababa",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+251",
      supported_genders: %w[male female],
      patient_line_list_show_zone: false,
      dhis2_data_elements: {
        cumulative_assigned: "nrK3Yj6ELl0",
        cumulative_assigned_adjusted: "YKsRrnjBiVE",
        controlled: "ZCkeHFQETzb",
        uncontrolled: "z4mVPviB8OH",
        missed_visits: "tNRBsYt0ZOK",
        ltfu: "qI3kE1DizFL",
        dead: "ZNYhcG2efAB",
        cumulative_registrations: "PX8qBGsdF5G",
        monthly_registrations: "Tx3CKEUFqNN"
      },
      appointment_reminders_channel: Messaging::Twilio::Sms
    },
    LK: {
      abbreviation: "LK",
      name: "Sri Lanka",
      extended_region_reports: false,
      states: COUNTRYWISE_STATES["Sri Lanka"],
      dashboard_locale: ENV["DEFAULT_PREFERRED_DASHBOARD_LOCALE"] || "en_LK",
      faker_locale: "en-IND",
      time_zone: ENV["DEFAULT_TIME_ZONE"] || "Asia/Colombo",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+94",
      supported_genders: %w[male female],
      patient_line_list_show_zone: false,
      appointment_reminders_channel: Messaging::Twilio::Sms
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
      appointment_reminders_channel: Messaging::Twilio::Sms
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
      appointment_reminders_channel: Messaging::Twilio::Sms
    }
  }.with_indifferent_access.freeze

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
