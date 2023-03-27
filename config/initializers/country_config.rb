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
      custom_drug_category_order: %w[hypertension_ccb hypertension_arb hypertension_diuretic diabetes],
      maharashtra_dhis2_data_elements: {
        monthly_registrations_male: "F0cPY1T9lNs.tY82VK3LTQq",
        monthly_registrations_female: "F0cPY1T9lNs.VHbljVQ8REF",
        controlled_male: "FSuHsnyPYcV.tY82VK3LTQq",
        controlled_female: "FSuHsnyPYcV.VHbljVQ8REF"
      },
      appointment_reminders_channel: "Messaging::Bsnl::Sms"
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
        cumulative_assigned: "eNtDKQTRdto",
        cumulative_assigned_adjusted: "jCn7IIHtlXf",
        controlled: "oVfmtlxYhOH",
        uncontrolled: "QO2eTU3dW18",
        missed_visits: "w7NRchlv0Rb",
        ltfu: "w91dERGRhJ4",
        dead: "SyduEtVKvlF",
        cumulative_registrations: "bdMBWIf2i1h",
        monthly_registrations: "tI9g0mtCzOv"
      },
      disaggregated_dhis2_data_elements: {
        htn_controlled_patients: "AA6Oc6DV3Lh",
        htn_uncontrolled_patients: "zdjelro1SmB",
        htn_cumulative_assigned_patients: "G6Btpbfkq2W",
        htn_cumulative_assigned_patients_adjusted: "Xf20lyLSBmA",
        htn_cumulative_registered_patients: "aiFkmP0vSur",
        htn_dead_patients: "bIO8RQ1zSC7",
        htn_monthly_registered_patients: "svwuMGBC3to",
        htn_patients_lost_to_follow_up: "kjt9YiJPRYT",
        htn_patients_who_missed_visits: "DktVuX67zy3"
      },
      dhis2_category_option_combo: {
        male_15_19: "lD5fJ7FH7F5",
        male_20_24: "I9QB4B7Bjaz",
        male_25_29: "eodikMeezug",
        male_30_34: "jFKCwmWrZDY",
        male_35_39: "wJR0cZ3Ey12",
        male_40_44: "pV6YSOlu7bN",
        male_45_49: "O8Qwzk07pir",
        male_50_54: "ZoXrml6y2Mx",
        male_55_59: "xN9o5e6StnS",
        male_60_64: "ySojwKytqQd",
        male_65_69: "BJpFzvDeI3c",
        male_70_74: "rm7nAl3Svmo",
        male_75_plus: "orG8grjcMSq",
        female_15_19: "mIVgzotqxo1",
        female_20_24: "NFT55GaW4jy",
        female_25_29: "GWxwHYzjEu1",
        female_30_34: "HrPHULh80ak",
        female_35_39: "bW5iuiTQ9Zn",
        female_40_44: "Kxs8QxcxLwm",
        female_45_49: "VGZh8BeNyd8",
        female_50_54: "DfZvQ84V53t",
        female_55_59: "NTVCB0eSIEc",
        female_60_64: "aK96j6tDRU7",
        female_65_69: "rPUciQ3Do31",
        female_70_74: "sDSbNtoPUdE",
        female_75_plus: "p9Y5Qp2F0ER",
        third_sex_15_19: "dTGIWpIRN53",
        third_sex_20_24: "N1Epvb2xA1o",
        third_sex_25_29: "VOluq9JQ69l",
        third_sex_30_34: "e7WxYJzM2XX",
        third_sex_35_39: "LSIo9sZ9c3N",
        third_sex_40_44: "Vck9PpDTEby",
        third_sex_45_49: "Wi7uegBRKew",
        third_sex_50_54: "JQrTthw6DAa",
        third_sex_55_59: "z4kY6YX9FdA",
        third_sex_60_64: "fVZFXNaMWCF",
        third_sex_65_69: "oPc5eh0j1Z9",
        third_sex_70_74: "AdYyauSwEI1",
        third_sex_75_plus: "eMIKquRyZZh"
      },
      enabled_diabetes_population_coverage: true,
      appointment_reminders_channel: "Messaging::AlphaSms::Sms"
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
        cumulative_assigned_adjusted: "DxHkdQjTpXC",
        controlled: "ZCkeHFQETzb",
        uncontrolled: "z4mVPviB8OH",
        missed_visits: "tNRBsYt0ZOK",
        ltfu: "qI3kE1DizFL",
        dead: "ZNYhcG2efAB",
        cumulative_registrations: "PX8qBGsdF5G",
        monthly_registrations: "Tx3CKEUFqNN"
      },
      appointment_reminders_channel: "Messaging::Twilio::ReminderSms"
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
