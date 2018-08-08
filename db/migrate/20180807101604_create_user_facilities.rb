class CreateUserFacilities < ActiveRecord::Migration[5.1]
  def change
    create_table :user_facilities, id: :uuid do |t|
      t.belongs_to :user, index: true, type: :uuid, null: false
      t.belongs_to :facility, index: true, type: :uuid, null: false
      t.timestamps
    end
    add_index :user_facilities, [:user_id, :facility_id], unique: true
  end
end
