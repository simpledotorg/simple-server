require "rails_helper"

RSpec.describe Imo::InviteUnsubscribedPatients, type: :job do
  let(:date) { "1-1-2020".to_date }

  describe "#perform" do
    it "does nothing when feature flag is off" do
      create(:patient)
      expect(Imo::InvitePatient).not_to receive(:perform_at)
      described_class.perform_async
      described_class.drain
    end

    it "queues an Imo::InvitePatient job for patients who have no ImoAuthorization" do
      patient = create(:patient)
      Flipper.enable(:imo_messaging)
      Timecop.freeze(date) do
        expect(Imo::InvitePatient).to receive(:perform_at).with(date, patient.id)
        described_class.perform_async
        described_class.drain
      end
    end

    it "queues an Imo::InvitePatient job for non-subscribed patients who were invited over 6 months ago" do
      patient = create(:patient)
      create(:imo_authorization, patient: patient, status: "invited", last_invited_at: date - 7.months)
      Flipper.enable(:imo_messaging)
      Timecop.freeze(date) do
        expect(Imo::InvitePatient).to receive(:perform_at).with(date, patient.id)
        described_class.perform_async
        described_class.drain
      end
    end

    it "does not queue an Imo::InvitePatient job for patients who were invited less than six months ago" do
      patient = create(:patient)
      create(:imo_authorization, patient: patient, status: "invited", last_invited_at: 1.day.ago)
      Flipper.enable(:imo_messaging)
      expect(Imo::InvitePatient).not_to receive(:perform_at)
      described_class.perform_async
      described_class.drain
    end

    it "does not queue an Imo::InvitePatient job for patients who have been successfully subscribed" do
      patient = create(:patient)
      create(:imo_authorization, patient: patient, status: "subscribed", last_invited_at: 1.year.ago)
      Flipper.enable(:imo_messaging)
      expect(Imo::InvitePatient).not_to receive(:perform_at)
      described_class.perform_async
      described_class.drain
    end
  end
end
