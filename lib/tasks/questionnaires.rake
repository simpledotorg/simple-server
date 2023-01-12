require "tasks/scripts/seed_questionnaire_responses"

namespace :questionnaires do
  desc "Seed questionnaire responses with empty content"
  task seed_questionnaire_responses: :environment do
    SeedQuestionnaireResponses.call
  end
end
