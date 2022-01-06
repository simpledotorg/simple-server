# frozen_string_literal: true

require "rails_helper"
require "tasks/scripts/mark_transferred_patients"

RSpec.describe MarkTransferredPatient do
  context "for a patient with last appointment cancelled" do
    let!(:patient) { create(:patient) }

    context "due to moved_to_private" do
      let!(:appointment) { create(:appointment, patient: patient, cancel_reason: :moved_to_private) }

      it "sets the status on patient to migrated" do
        described_class.call

        expect(patient.reload.status).to eq "migrated"
      end
    end

    context "due to public_hospital_transfer" do
      let!(:appointment) { create(:appointment, patient: patient, cancel_reason: :public_hospital_transfer) }

      it "sets the status on patient to migrated" do
        described_class.call

        expect(patient.reload.status).to eq "migrated"
      end
    end

    context "due to other reasons" do
      let!(:appointment) { create(:appointment, patient: patient, cancel_reason: :not_responding) }
      it "does not set the status on patient to migrated" do
        described_class.call

        expect(patient.reload.status).to eq "active"
      end
    end
  end

  context "for a patient with latest appointment not cancelled" do
    let!(:patient) { create(:patient) }
    let!(:earlier_appointment) { create(:appointment, patient: patient, updated_at: 1.day.ago, cancel_reason: :moved_to_private) }
    let!(:latest_appointment) { create(:appointment, patient: patient) }

    it "doesn't set the status to migrated" do
      described_class.call

      expect(patient.reload.status).to eq "active"
    end
  end
end
