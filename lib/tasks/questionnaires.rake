namespace :questionnaires do
  desc "Initialize questionnaire responses"
  task initialize: :environment do
    # Due to mismatch in Gregorian<>Ethiopian calendars,
    # Dynamic forms initialization had a delay of 20+ days in Ethiopia.
    # To avoid this delay, we initialize dynamic forms 1 month in advance in Ethiopia.
    date = CountryConfig.current_country?("Ethiopia") ? Date.current : -1.month.from_now

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
