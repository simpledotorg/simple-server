# frozen_string_literal: true

class RemoveInvalidBuhsDrugs < ActiveRecord::Migration[6.1]
  ORG_ID = "afb485a8-094e-4d86-812f-0bac90934d89"

  def up
    unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?
      return print "RemoveInvalidBuhsDrugs is only for production Bangladesh"
    end

    destroyed_drugs = PrescriptionDrug
      .joins(facility: {facility_group: :organization})
      .where(organization: {id: ORG_ID})
      .where("prescription_drugs.updated_at < ?", Date.new(2024, 3, 8))
      .destroy_all

    puts "deleted:\n #{destroyed_drugs.size} drugs"
  end

  def down
    puts "This migration cannot be reversed."
  end
end
