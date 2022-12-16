class CreateQuestionnaires < ActiveRecord::Migration[6.1]
  def change
    create_table :questionnaires, id: :uuid do |t|
      t.string :questionnaire_type, null: false
      t.integer :questionnaire_dsl_version, null: false
      t.jsonb :layout, null: false
      t.timestamp :created_at, null: false
      t.timestamp :deleted_at
    end
  end
end
