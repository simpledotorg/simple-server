namespace :questionnaires do
  desc "Initialize questionnaire responses"
  task initialize: :environment do
    # Due to mismatch in Gregorian<>Ethiopian calendars,
    # Dynamic forms initialization had a delay of 30+ days in Ethiopia.
    # To avoid this delay, we initialize dynamic forms 2 months in advance in Ethiopia.
    date = CountryConfig.current_country?("Ethiopia") ? 1.month.from_now : 1.month.ago

    if Flipper.enabled?(:monthly_screening_reports)
      QuestionnaireResponses::MonthlyScreeningReports.new(date).seed
    end
    if Flipper.enabled?(:monthly_supplies_reports)
      QuestionnaireResponses::MonthlySuppliesReports.new(date).seed
    end
    if Flipper.enabled?(:drug_stock_questionnaires)
      QuestionnaireResponses::DrugStockReports.new(date).seed
    end
  end
end
