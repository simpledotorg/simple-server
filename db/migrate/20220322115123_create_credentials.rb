class CreateCredentials < ActiveRecord::Migration[5.2]
  def change
    create_table :credentials, id: false, primary_key: :name do |t|
      t.string :name, null: false
      t.string :value, null: false

      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
