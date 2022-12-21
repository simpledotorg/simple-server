class CreateQuestionnaires < ActiveRecord::Migration[6.1]
  def change
    create_table :questionnaire_versions, id: :uuid do |t|
      t.string :questionnaire_type, null: false
      t.integer :dsl_version, null: false
      t.jsonb :layout, null: false
      t.timestamp :created_at, null: false
    end

    create_table :questionnaires, id: false, primary_key: :version_id do |t|
      t.uuid :version_id, null: false
      t.string :questionnaire_type, null: false
      t.integer :dsl_version, null: false
      t.timestamp :updated_at, null: false
      t.timestamp :deleted_at

      t.index [:questionnaire_type, :dsl_version], unique: true
    end

    # TO_THINK: Shall we put FK constraint on all 3 columns: id, type & dsl_version?
    add_foreign_key(:questionnaires, :questionnaire_versions, column: :version_id)
  end
end
