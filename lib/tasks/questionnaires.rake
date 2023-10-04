namespace :questionnaires do
  desc "Initialize questionnaire responses"
  task initialize: :environment do
    date = CountryConfig.current_country?("Ethiopia") ? Date.current : 1.month.ago

    if Flipper.enabled?(:monthly_screening_reports)
      QuestionnaireResponses::MonthlyScreeningReports.new(date).pre_fill
    end
    if Flipper.enabled?(:monthly_supplies_reports)
      QuestionnaireResponses::MonthlySuppliesReports.new(date).seed
    end
    if Flipper.enabled?(:drug_stock_questionnaires)
      QuestionnaireResponses::DrugStockReports.new(date).seed
    end
  end
end
