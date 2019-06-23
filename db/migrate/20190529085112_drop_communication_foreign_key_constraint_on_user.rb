class DropCommunicationForeignKeyConstraintOnUser < ActiveRecord::Migration[5.1]
  def change
    remove_foreign_key :communications, :users
  end
end
