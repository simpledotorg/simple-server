class SeedQuestionnaireResponses
  def self.call
    Questionnaire.monthly_screening_reports.active.product(Facility.all).each do |questionnaire, facility|
      QuestionnaireResponse.create(
        questionnaire: questionnaire.id,
        facility: facility.id,
        user_id: nil,
        content: {},
        device_created_at: Time.now,
        device_updated_at: Time.now
      )
    end
  end
end
