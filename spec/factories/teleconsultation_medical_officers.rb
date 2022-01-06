# frozen_string_literal: true

FactoryBot.define do
  factory :teleconsultation_medical_officer, class: TeleconsultationMedicalOfficer, parent: :user do
    teleconsultation_facilities { [create(:facility)] }
  end
end
