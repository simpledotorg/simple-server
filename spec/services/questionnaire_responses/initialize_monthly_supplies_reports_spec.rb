require 'rspec'

describe 'QuestionnaireResponses::InitializeMonthlySuppliesReports' do

  before :each do
    Flipper.enable(:monthly_supplies_report)
    create(:questionnaire, :active, questionnaire_type: Questionnaire.monthly_supplies_reports)
    refresh_views
  end
  
  describe '#call' do
    it 'should ' do
      
    end

  end
end
