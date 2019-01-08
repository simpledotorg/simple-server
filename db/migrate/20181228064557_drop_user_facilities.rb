class DropUserFacilities < ActiveRecord::Migration[5.1]
  def change
    drop_table :user_facilities
  end
end
