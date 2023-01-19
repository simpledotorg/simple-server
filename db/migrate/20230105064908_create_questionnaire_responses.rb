class CreateQuestionnaireResponses < ActiveRecord::Migration[6.1]
  def change
    create_table :questionnaire_responses, id: :uuid do |t|
      t.uuid :questionnaire_id, null: false
      t.uuid :facility_id, null: false
      t.uuid :user_id
      t.jsonb :content, null: false, default: {}
      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false
      t.timestamps
      t.datetime :deleted_at

      t.index :facility_id
      t.index :updated_at

      t.foreign_key :questionnaires, column: :questionnaire_id
    end

    add_index :questionnaires, :updated_at
  end
end
