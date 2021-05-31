class AddRegionIdToDrugStock < ActiveRecord::Migration[5.2]
  def change
    add_column :drug_stocks, :region_id, :uuid, foreign_key: true
    change_column_null :drug_stocks, :facility_id, true
  end
end
