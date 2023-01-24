class UpdateQuestionnaireResponses < ActiveRecord::Migration[6.1]
  def up
    rename_column :questionnaire_responses, :user_id, :last_updated_by_user_id
  end

  def down
    rename_column :questionnaire_responses, :last_updated_by_user_id, :user_id
  end
end
