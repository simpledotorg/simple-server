# frozen_string_literal: true

FactoryBot.define do
  factory :imo_authorization do
    last_invited_at { Time.current }
    status { "invited" }
    patient {}
  end
end
