require_dependency "seed/config"

module Seed
  class QuestionnaireSeeder
    def self.call
      FactoryBot.create(:questionnaire,
                        questionnaire_type: "monthly_screening_reports",
                        dsl_version: 1,
                        is_active: true,
                        description: "A specimen screening report created during seeding.",
                        layout: Api::V4::Models::Questionnaires::SpecimenLayout.dsl_version1)

      FactoryBot.create(:questionnaire,
                        questionnaire_type: "monthly_supplies_reports",
                        dsl_version: 2,
                        is_active: true,
                        metadata: "supplies_reports, specimen-seed",
                        layout: Api::V4::Models::Questionnaires::SpecimenLayout.dsl_version2)

      (1..3).map do |n|
        QuestionnaireResponses::PreFillMonthlyScreeningReports.call(n.month.ago)
        QuestionnaireResponses::InitializeMonthlySuppliesReports.call(n.month.ago)
      end
    end
  end
end
