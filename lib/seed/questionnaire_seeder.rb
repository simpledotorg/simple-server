require_dependency "seed/config"

module Seed
  class QuestionnaireSeeder
    def self.call
      FactoryBot.create(:questionnaire,
        questionnaire_type: "monthly_screening_reports",
        dsl_version: "1",
        is_active: true,
        description: "A specimen screening report created during seeding.",
        layout: Api::V4::Models::Questionnaires::SpecimenLayout.dsl_version1)
      # TODO: change the specimen layout's text to have translation keys instead of english text?

      FactoryBot.create(:questionnaire,
        questionnaire_type: "monthly_supplies_reports",
        dsl_version: "1.1",
        is_active: true,
        description: "specimen report, supplies report, dsl version 1.1",
        layout: Api::V4::Models::Questionnaires::SpecimenLayout.dsl_version1_1)

      (1..3).map do |n|
        QuestionnaireResponses::PreFillMonthlyScreeningReports.call(n.month.ago)
        QuestionnaireResponses::InitializeMonthlySuppliesReports.call(n.month.ago)
      end
    end
  end
end
