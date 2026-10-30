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
      appointment_reminders_channel: "Messaging::Bsnl::Sms",
      sorted_facility_sizes: %w[large medium small community],
      facility_sizes: {
        community: "community",
        small: "small",
        medium: "medium",
        large: "large"
      }
    },
    BD: {
      abbreviation: "BD",
      drug_stock_tracking_organization_slug: "nhf",
      qi_reports: {
        enabled: true,
        level: "district",
        division_label: "Division",
        place_label: "District",
        # Settings for script/qi_reports/publish_district_reports.py (read with `rails qi_reports:settings`)
        script: {
          name: "Bangladesh",
          place_noun: "district",
          footer_note: "NHF facilities only",
          months: 6,
          exclude: [
            "Temp District"
          ],
          place_list_sql: "SELECT DISTINCT district_name FROM reporting_facilities WHERE district_name IS NOT NULL ORDER BY 1",
          reports: [
            {
              name: "Titration",
              card_id: 997,
              place_filter: "district_name",
              start_filter: "start_date",
              end_filter: "end_date",
              per_month: true,
              lowercase_place: false,
              place_col: "district_name",
              month_col: "month_date",
              numerator_col: "titrated",
              denominator_col: "uncontrolled",
              percent_col: "percent_titrated",
              headline: "% of uncontrolled patients titrated",
              description: "Hypertension patients with uncontrolled BP whose treatment was intensified during the month",
              numerator_label: "Titrated",
              denominator_label: "Uncontrolled",
              sentence: "{num} patients titrated<br/>of {den} patients with uncontrolled BP in {month}"
            },
            {
              name: "Statins",
              csv: "statins.csv",
              csv_hint: "run Metabase question 1523, download the results as CSV and save it here",
              place_col: "district",
              month_col: "month_date",
              numerator_col: "statin_patients",
              denominator_col: "the_eligible_patients",
              percent_col: "percentage_statin_patients",
              headline: "% of eligible patients prescribed statins",
              description: "Patients eligible for statins who have been prescribed a statin",
              numerator_label: "On statins",
              denominator_label: "Eligible",
              sentence: "{num} patients prescribed statins<br/>of {den} eligible patients in {month}"
            }
          ]
        }
      },
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
      appointment_reminders_channel: "Messaging::AlphaSms::Sms",
      sorted_facility_sizes: %w[large medium small community],
      facility_sizes: {
        community: "community",
        small: "small",
        medium: "medium",
        large: "large"
      }
    },
    ET: {
      abbreviation: "ET",
      # Ethiopia's QI reports are per region (state level), so only one dropdown is shown. Switch on
      # (enabled: true) once its script settings below have been tested against its Metabase.
      qi_reports: {
        enabled: false,
        level: "state",
        place_label: "Region",
        script: {
          name: "Ethiopia",
          place_noun: "region",
          footer_note: "RTSL facilities only",
          months: 6,
          exclude: [],
          place_list_sql: "SELECT DISTINCT state_name FROM reporting_facilities WHERE state_name IS NOT NULL ORDER BY 1",
          reports: [
            {
              name: "Titration",
              card_id: 255,
              place_filter: "state_name",
              start_filter: "start_date",
              end_filter: "end_date",
              per_month: true,
              lowercase_place: false,
              place_col: "state_name",
              month_col: "month_date",
              numerator_col: "titrated",
              denominator_col: "uncontrolled",
              percent_col: "percent_titrated",
              headline: "% of uncontrolled patients titrated",
              description: "Hypertension patients with uncontrolled BP whose treatment was intensified during the month",
              numerator_label: "Titrated",
              denominator_label: "Uncontrolled",
              sentence: "{num} patients titrated<br/>of {den} patients with uncontrolled BP in {month}"
            },
            {
              name: "Statins",
              csv: "statins-ethiopia.csv",
              csv_hint: "run Metabase question 266 for every region, or an all-regions version of it, download the results as CSV and save it here",
              place_col: "state",
              month_col: "month_date",
              numerator_col: "statin_patients",
              denominator_col: "the_eligible_patients",
              percent_col: "percentage_statin_patients",
              headline: "% of eligible patients prescribed statins",
              description: "Patients with diabetes aged 40 or over, a history of stroke or heart attack, or a CV risk score of 10 or more, who have been prescribed a statin",
              numerator_label: "On statins",
              denominator_label: "Eligible",
              sentence: "{num} patients prescribed statins<br/>of {den} eligible patients in {month}"
            }
          ]
        }
      },
      name: "Ethiopia",
      extended_region_reports: true,
      states: COUNTRYWISE_STATES["Ethiopia"],
      dashboard_locale: ENV["DEFAULT_PREFERRED_DASHBOARD_LOCALE"] || "en-ET",
      faker_locale: "en-IND",
      time_zone: ENV["DEFAULT_TIME_ZONE"] || "Africa/Addis_Ababa",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+251",
      supported_genders: %w[male female],
      patient_line_list_show_zone: false,
      appointment_reminders_channel: "Messaging::Twilio::ReminderSms",
      sorted_facility_sizes: %w[large medium small community],
      facility_sizes: {
        community: "community",
        small: "small",
        medium: "medium",
        large: "large"
      }
    },
    LK: {
      abbreviation: "LK",
      name: "Sri Lanka",
      extended_region_reports: true,
      states: COUNTRYWISE_STATES["Sri Lanka"],
      dashboard_locale: ENV["DEFAULT_PREFERRED_DASHBOARD_LOCALE"] || "en-LK",
      faker_locale: "en-IND",
      time_zone: ENV["DEFAULT_TIME_ZONE"] || "Asia/Colombo",
      sms_country_code: ENV["SMS_COUNTRY_CODE"] || "+94",
      supported_genders: %w[male female],
      patient_line_list_show_zone: false,
      appointment_reminders_channel: "Messaging::Mobitel::Sms",
      sorted_facility_sizes: %w[large medium small community teaching_hospital national_hospital arogya_wellness_centre],
      facility_sizes: {
        community: "community",
        small: "small",
        medium: "medium",
        large: "large",
        national_hospital: "national_hospital",
        teaching_hospital: "teaching_hospital",
        arogya_wellness_centre: "arogya_wellness_centre"
      }
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
      appointment_reminders_channel: "Messaging::Twilio::ReminderSms",
      sorted_facility_sizes: %w[large medium small community],
      facility_sizes: {
        community: "community",
        small: "small",
        medium: "medium",
        large: "large"
      }
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
      appointment_reminders_channel: "Messaging::Twilio::ReminderSms",
      sorted_facility_sizes: %w[large medium small community],
      facility_sizes: {
        community: "community",
        small: "small",
        medium: "medium",
        large: "large"
      }
    }
  }.with_indifferent_access.freeze

  class << self
    def dhis2_data_elements
      YAML.load_file(ENV.fetch("DHIS2_DATA_ELEMENTS_FILE")).with_indifferent_access
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

  def self.supported_genders
    current[:supported_genders] || %w[male female transgender]
  end
end

Rails.application.config.country = CountryConfig.for(ENV.fetch("DEFAULT_COUNTRY"))
Dotenv.overload(CountryConfig.country_environment_file)
