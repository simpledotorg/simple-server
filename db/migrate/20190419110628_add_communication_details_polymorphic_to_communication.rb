class AddCommunicationDetailsPolymorphicToCommunication < ActiveRecord::Migration[5.1]
  def up
    change_table :communications do |t|
      t.references :detailable, polymorphic: true
    end
  end

  def down
    change_table :communications do |t|
      t.remove_references :detailable, polymorphic: true
    end
  end
end
