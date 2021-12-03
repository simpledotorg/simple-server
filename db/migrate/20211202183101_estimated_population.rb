class EstimatedPopulation < ActiveRecord::Migration[5.2]
  def change
    create_table :estimated_populations do |t|
      t.integer :population, null: false
      t.string :diagnosis, null: false, default: "HTN"
      t.uuid :region_id, null: false
      t.uuid :created_by_user_id
      t.uuid :updated_by_user_id
      t.datetime :deleted_at
    end
  end
end
