# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeleconsultationMedicalOfficer, type: :model do
  describe "default scope" do
    it "contains only users who can teleconsult" do
      users = [create(:teleconsultation_medical_officer),
        create(:teleconsultation_medical_officer, teleconsultation_facilities: [])]

      expect(TeleconsultationMedicalOfficer.all).to contain_exactly users.first
    end
  end
end
