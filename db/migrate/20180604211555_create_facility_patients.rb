class CreateFacilityPatients < ActiveRecord::Migration[5.1]
  def change
    create_table :facility_patients do |t|
      t.belongs_to :facility, type: :uuid, foreign_key: true
      t.belongs_to :patient, type: :uuid, foreign_key: true

      t.timestamps
    end
  end
end
