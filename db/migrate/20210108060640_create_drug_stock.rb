class CreateDrugStock < ActiveRecord::Migration[5.2]
  def change
    create_table :drug_stocks, id: :uuid do |t|
      t.references :facility, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :protocol_drug, type: :uuid, null: false, foreign_key: true

      t.integer :in_stock, null: false
      t.integer :received

      t.datetime :recorded_at, null: false
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
