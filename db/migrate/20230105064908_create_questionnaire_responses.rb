class CreateQuestionnaireResponses < ActiveRecord::Migration[6.1]
  def change
    create_table :questionnaire_responses, id: :uuid do |t|
      t.uuid :questionnaire_id
      t.uuid :facility_id
      t.uuid :user_id
      t.jsonb :content
      t.datetime :device_created_at
      t.datetime :device_updated_at
      t.timestamps
      t.datetime :deleted_at

      t.index :facility_id
      t.index :updated_at
    end

    add_index :questionnaires, :updated_at
  end
end
