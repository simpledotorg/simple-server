class CreateDrRaiDataTitrations < ActiveRecord::Migration[6.1]
  def change
    create_table :dr_rai_data_titrations do |t|
      t.string :facility_name
      t.integer :titrated_count
      t.integer :follow_up_count
      t.datetime :month_date
      t.decimal :titration_rate, precision: 5, scale: 2

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }, null: false
    end
  end
end
