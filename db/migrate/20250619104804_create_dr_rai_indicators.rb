class CreateDrRaiIndicators < ActiveRecord::Migration[6.1]
  def change
    create_table :dr_rai_indicators do |t|
      t.string :title
      t.timestamp :deleted_at

      t.timestamps
    end
  end
end
