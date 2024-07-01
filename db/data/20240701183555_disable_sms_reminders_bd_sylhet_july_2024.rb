# frozen_string_literal: true

class DisableSmsRemindersBdSylhetJuly2024 < ActiveRecord::Migration[6.1]
  DISTRICTS_NO_SYLHET = %w[Moulvibazar Habiganj Sunamganj Barishal Jhalokathi Feni
    Chattogram Bandarban Pabna Rajshahi Sirajganj Sherpur Jamalpur].freeze

  INCLUDED_FACILITY_SLUG = Facility.where(facility_type: "UHC", district: DISTRICTS).pluck(:slug)

  UPDATED_REGION_FILTERS = {
    "facilities" => {"include" => INCLUDED_FACILITY_SLUG}
  }.freeze

  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    %w[Jul Aug Sep Oct].each do |month|
      Experimentation::Experiment.find_by_name("Current patient #{month} 2024")&.update!(filters: UPDATED_REGION_FILTERS)
      Experimentation::Experiment.find_by_name("Stale patient #{month} 2024")&.update!(filters: UPDATED_REGION_FILTERS)
    end
  end

  def down
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?
    puts "This migration cannot be reversed. To include Sylhet again, create a new migration."
  end
end
