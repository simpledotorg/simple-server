FactoryBot.define do
  factory :imo_authorization do
    last_invited_at { Time.current }
    status { "invited" }
    patient {}
  end
end
