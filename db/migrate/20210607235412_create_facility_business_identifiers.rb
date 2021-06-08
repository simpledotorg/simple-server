class CreateFacilityBusinessIdentifiers < ActiveRecord::Migration[5.2]
  def change
    create_table :facility_business_identifiers do |t|
      t.string :identifier, null: false
      t.string :identifier_type, null: false
      t.belongs_to :facility, type: :uuid, null: false
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
