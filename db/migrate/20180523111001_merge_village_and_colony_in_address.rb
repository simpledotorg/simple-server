class MergeVillageAndColonyInAddress < ActiveRecord::Migration[5.1]
  def change
    rename_column :addresses, :village, :village_or_colony
    remove_column :addresses, :colony, :string
  end
end
