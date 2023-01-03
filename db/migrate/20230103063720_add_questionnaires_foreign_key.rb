class AddQuestionnairesForeignKey < ActiveRecord::Migration[6.1]

  def up
    ActiveRecord::Base.connection.execute('ALTER TABLE "questionnaires" ADD CONSTRAINT fk_questionnaire_versions_id_type_dsl FOREIGN KEY ("version_id", "questionnaire_type", "dsl_version") REFERENCES "questionnaire_versions" ("id", "questionnaire_type", "dsl_version");')
  end

  def down
    ActiveRecord::Base.connection.execute('ALTER TABLE "questionnaires" DROP CONSTRAINT fk_questionnaire_versions_id_type_dsl;')
  end
end
