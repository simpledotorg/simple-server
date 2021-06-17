require "rails_helper"

RSpec.describe Imo::InviteUnsubscribedPatients, type: :job do
  describe "#perform" do
    it "does nothing when feature flag is off" do
      create(:patient)
      expect(Imo::InvitePatient).not_to receive(:perform_now)
      described_class.perform_now
    end

    it "queues an Imo::InvitePatient job for patients who have no ImoAuthorization" do
      patient = create(:patient)
      Flipper.enable(:imo_messaging)
      expect(Imo::InvitePatient).to receive(:perform_now).with(patient.id)
      described_class.perform_now
    end

    it "does not queue an Imo::InvitePatient job for patients who have a recent ImoAuthorization" do
      patient = create(:patient)
      create(:imo_authorization, patient: patient, status: "invited", last_invited_at: 1.day.ago)
      Flipper.enable(:imo_messaging)
      expect(Imo::InvitePatient).not_to receive(:perform_now)
      described_class.perform_now
    end

    it "queues an Imo::InvitePatient job for patients who were invited over 6 months ago" do
      patient = create(:patient)
      create(:imo_authorization, patient: patient, status: "invited", last_invited_at: 7.months.ago)
      Flipper.enable(:imo_messaging)
      expect(Imo::InvitePatient).to receive(:perform_now).with(patient.id)
      described_class.perform_now
    end

    it "does not queue an Imo::InvitePatient job for patients who have an ImoAuthorization that is status 'subscribed'" do
      patient = create(:patient)
      create(:imo_authorization, patient: patient, status: "subscribed", last_invited_at: 1.year.ago)
      Flipper.enable(:imo_messaging)
      expect(Imo::InvitePatient).not_to receive(:perform_now)
      described_class.perform_now
    end
  end
end
