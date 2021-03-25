class CreateExperiments < ActiveRecord::Migration[5.2]
  def change
    create_table :experiments, id: :uuid do |t|
      t.string :name, null: false
      t.string :state, null: false
      t.date :start_date, null: true
      t.date :end_date, null: true
      t.timestamps null: false
    end

    add_index :experiments, :name, unique: true
  end
end
