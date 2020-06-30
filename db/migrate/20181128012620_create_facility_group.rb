class CreateFacilityGroup < ActiveRecord::Migration[5.1]
  def change
    create_table :facility_groups, id: :uuid do |t|
      t.string :name
      t.text :description
      t.references :organization, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end

    add_reference :facilities, :facility_group, type: :uuid, foreign_key: true
  end
end
