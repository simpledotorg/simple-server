require "rails_helper"

RSpec.describe Imo::InviteUnsubscribedPatients, type: :job do
  describe "#perform" do
    it "does nothing when feature flag is off" do
      patient = create(:patient)
      expect(Imo::InvitePatient).not_to receive(:perform_now)
      described_class.perform_now
    end

    it "queues an Imo::InvitePatient job for patients who have no ImoAuthorization" do
      patient = create(:patient)
      Flipper.enable(:imo_messaging)
      expect(Imo::InvitePatient).to receive(:perform_now)
      described_class.perform_now
    end
  end
end