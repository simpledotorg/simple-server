require "rails_helper"

RSpec.describe Imo::InvitePatient, type: :job do
  describe "#perform" do
      it "does nothing with feature flag turned off" do
        patient = create(:patient)
        allow_any_instance_of(ImoApiService).to receive(:invite)

        expect {
          described_class.perform_async(patient.id)
          described_class.drain
        }.not_to change { ImoAuthorization.count }
      end

    context "with feature flag turned on" do
      before { Flipper.enable(:imo_messaging) }

      it "raises an error when the patient id is not found" do
        expect {
          described_class.perform_async("fake")
          described_class.drain
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "invites the patient to Imo" do
        patient = create(:patient)
        imo_service = double
        allow(ImoApiService).to receive(:new).with(patient).and_return(imo_service)
        expect(imo_service).to receive(:invite)

        described_class.perform_async(patient.id)
        described_class.drain
      end
    end
  end
end
