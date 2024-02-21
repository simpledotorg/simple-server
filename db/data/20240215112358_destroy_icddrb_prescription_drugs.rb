# frozen_string_literal: true

class DestroyIcddrbPrescriptionDrugs < ActiveRecord::Migration[6.1]
  ORG_ID = "1bb836eb-9a0b-4646-96ad-7342b53a9155"

  def up
    unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?
      return print "DestroyIcddrbPrescriptionDrugs is only for production Bangladesh"
    end

    destroyed_drugs = PrescriptionDrug
      .joins(facility: {facility_group: :organization})
      .where(organization: {id: ORG_ID})
      .destroy_all

    puts "deleted:\n #{destroyed_drugs.size} drugs"
  end

  def down
    puts "This migration cannot be reversed."
  end
end
