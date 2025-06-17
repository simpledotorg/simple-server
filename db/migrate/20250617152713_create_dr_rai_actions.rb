class CreateDrRaiActions < ActiveRecord::Migration[6.1]
  def change
    create_table :dr_rai_actions do |t|
      t.string :content

      t.timestamps
    end
  end
end
