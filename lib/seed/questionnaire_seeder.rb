require_dependency "seed/config"
require "tasks/scripts/pre_fill_monthly_screening_reports"

module Seed
  class QuestionnaireSeeder
    def self.call
      FactoryBot.create(:questionnaire,
        questionnaire_type: "monthly_screening_reports",
        is_active: true,
        description: "screening_reports, specimen-seed",
        layout: Api::V4::Models::Questionnaires::MonthlyScreeningReport.layout)

      (1..3).map { |n| PreFillMonthlyScreeningReports.call(n.month.ago) }
    end
  end
end
