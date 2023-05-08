class AddDescriptionToQuestionnaires < ActiveRecord::Migration[6.1]
  def change
    add_column :questionnaires, :description, :string
  end
end
