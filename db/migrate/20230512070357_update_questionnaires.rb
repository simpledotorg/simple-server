class UpdateQuestionnaires < ActiveRecord::Migration[6.1]
  def up
    add_column :questionnaires, :description, :string
    change_column :questionnaires, :dsl_version, :decimal, precision: 4, scale: 2
  end

  def down
    remove_column :questionnaires, :description
    change_column :questionnaires, :dsl_version, :integer
  end
end
