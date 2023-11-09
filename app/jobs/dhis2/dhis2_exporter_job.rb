require "dhis2"

module Dhis2
  class Dhis2ExporterJob
    include Sidekiq::Job
    sidekiq_options retry: 2
    sidekiq_options queue: :default

    attr_reader :configuration, :client

    def initialize
      @configuration = Dhis2::Configuration.new.tap do |config|
        config.url = ENV.fetch("DHIS2_URL")
        config.user = ENV.fetch("DHIS2_USERNAME")
        config.password = ENV.fetch("DHIS2_PASSWORD")
        config.version = ENV.fetch("DHIS2_VERSION")
      end
      @client = Dhis2::Client.new(@configuration.client_params)
      @data_elements_map = CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements)
      if CountryConfig.dhis2_data_elements.key?(:dhis2_category_option_combo)
        @category_option_combo_ids = CountryConfig.dhis2_data_elements.fetch(:dhis2_category_option_combo)
      end
    end

    def last_n_month_periods(n)
      (Period.current.advance(months: -n)..Period.current.previous)
    end

    def export(data_values)
      response = @client.data_value_sets.bulk_create(data_values: data_values)
      Rails.logger.info("Exported to Dhis2 successfully", response)
    end
  end
end
