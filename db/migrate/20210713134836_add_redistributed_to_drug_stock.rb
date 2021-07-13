class AddRedistributedToDrugStock < ActiveRecord::Migration[5.2]
  def change
    add_column :drug_stocks, :redistributed, :integer
  end
end
