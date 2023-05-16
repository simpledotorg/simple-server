class UpdateQuestionnaires < ActiveRecord::Migration[6.1]
  def up
    add_column :questionnaires, :description, :string
    change_column :questionnaires, :dsl_version, :varchar
  end

  def down
    remove_column :questionnaires, :description
    change_column :questionnaires, :dsl_version, :integer, using: "dsl_version::integer"
  end
end
