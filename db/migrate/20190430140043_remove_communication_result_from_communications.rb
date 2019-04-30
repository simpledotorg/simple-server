class RemoveCommunicationResultFromCommunications < ActiveRecord::Migration[5.1]
  def change
    remove_column :communications, :communication_result, :string
  end
end
