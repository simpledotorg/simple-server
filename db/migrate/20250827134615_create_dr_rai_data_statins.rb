class CreateDrRaiDataStatins < ActiveRecord::Migration[6.1]
  def change
    create_table :dr_rai_data_statins do |t|
      t.string :aggregate_root
      t.integer :eligible_patients
      t.integer :patients_prescribed_statins
      t.datetime :month_date
      t.decimal :percentage_statins, precision: 5, scale: 2
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
