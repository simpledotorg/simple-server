class CreateDrRaiDataBpFudging < ActiveRecord::Migration[6.1]
  def change
    create_table :dr_rai_data_bp_fudgings do |t|
      t.string :state
      t.string :district
      t.string :slug
      t.string :quarter
      t.integer :numerator
      t.integer :denominator
      t.decimal :ratio, precision: 5, scale: 2
      t.datetime :deleted_at

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }, null: false
    end

    add_index :dr_rai_data_bp_fudgings, [:state, :district, :slug, :quarter], unique: true, name: 'index_dr_rai_data_bp_fudgings_on_state_district_slug_quarter'
  end
end
