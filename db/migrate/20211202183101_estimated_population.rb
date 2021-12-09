class EstimatedPopulation < ActiveRecord::Migration[5.2]
  def change
    create_table :estimated_populations, id: :uuid do |t|
      t.belongs_to :region, index: {unique: true}, foreign_key: true, type: :uuid, null: false
      t.integer :population, null: false
      t.string :diagnosis, null: false, default: "HTN"
      t.timestamps null: false
      t.datetime :deleted_at
    end
  end
end
