class CreateFacilities < ActiveRecord::Migration[5.1]
  def change
    create_table :facilities, id: :uuid do |t|
      t.string :name
      t.string :street_address
      t.string :village_or_colony
      t.string :district
      t.string :state
      t.string :country
      t.string :pin
      t.string :facility_type

      t.timestamps
    end
  end
end
