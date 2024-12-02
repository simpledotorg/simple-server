require 'rails_helper'

describe CvdRisk, type: :model do
  it_behaves_like "a syncable model"

  context "when a new record comes in for the same patient" do
    it "soft-deletes the previous record" do
      first_risk_score = create(:cvd_risk)
      the_patient = first_risk_score.patient
      expect(first_risk_score.deleted_at).to be nil
      create(:cvd_risk, patient: the_patient)
      expect(CvdRisk.count).to eq 1
      expect(CvdRisk.for_patient(the_patient.id).with_discarded.count).to eq 2
    end
  end

  context "Scopes" do
    describe "for_patient" do
      it "lists all patient's CVD risk scores" do
        risk = create(:cvd_risk)
        create(:cvd_risk)
        expect(CvdRisk.for_patient(risk.patient.id).count).to eq 1
      end
    end
  end
end
