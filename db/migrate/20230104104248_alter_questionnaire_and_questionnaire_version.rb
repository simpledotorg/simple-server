class AlterQuestionnaireAndQuestionnaireVersion < ActiveRecord::Migration[6.1]
  def change
    drop_table :questionnaires
    drop_table :questionnaire_versions

    create_table :questionnaires, id: :uuid do |t|
      t.string :questionnaire_type, null: false
      t.integer :dsl_version, null: false
      t.boolean :is_active, null: false
      t.jsonb :layout, null: false
      t.timestamps
      t.datetime :deleted_at

      t.index [:questionnaire_type, :dsl_version, :is_active], name: "index_questionnaires_uniqueness", unique: true, where: "is_active = true"
    end
  end
end
