# frozen_string_literal: true

class DisableSmsRemindersBdSylhetRajshahiAugOct2024 < ActiveRecord::Migration[6.1]
  # excluded districts: Sylhet, Rajshahi
  DISTRICTS = %w[Moulvibazar Habiganj Sunamganj Barishal Jhalokathi Feni
    Chattogram Bandarban Pabna Sirajganj Sherpur Jamalpur].freeze

  INCLUDED_FACILITY_SLUG = Facility.where(facility_type: "UHC", district: DISTRICTS).pluck(:slug)

  UPDATED_REGION_FILTERS = {
    "facilities" => {"include" => INCLUDED_FACILITY_SLUG}
  }.freeze

  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    %w[Aug Sep Oct].each do |month|
      Experimentation::Experiment.find_by_name("Current patient #{month} 2024")&.update!(filters: UPDATED_REGION_FILTERS)
      Experimentation::Experiment.find_by_name("Stale patient #{month} 2024")&.update!(filters: UPDATED_REGION_FILTERS)
    end
  end

  def down
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?
    puts "This migration cannot be reversed. To include Sylhet/Rajshahi again, create a new migration."
  end
end
