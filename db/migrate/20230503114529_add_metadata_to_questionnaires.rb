class AddMetadataToQuestionnaires < ActiveRecord::Migration[6.1]
  def change
    add_column :questionnaires, :metadata, :string
  end
end
