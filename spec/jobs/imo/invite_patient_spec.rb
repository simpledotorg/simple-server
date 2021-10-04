require "rails_helper"

RSpec.describe Imo::InvitePatient, type: :job do
  describe "#perform" do
    it "does nothing with feature flag turned off" do
      patient = create(:patient)
      allow_any_instance_of(ImoApiService).to receive(:send_invitation).and_return(:invited)

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

      it "creates an ImoAuthorization with a status returned by the imo service" do
        patient = create(:patient)
        imo_service = instance_double(ImoApiService, send_invitation: :invited)
        allow(ImoApiService).to receive(:new).and_return(imo_service)

        expect {
          described_class.perform_async(patient.id)
          described_class.drain
        }.to change{ patient.reload.imo_authorization }.from(nil)
        expect(patient.imo_authorization.status).to eq("invited")
      end

      it "raises an error when the returned status is not valid" do
        patient = create(:patient)
        imo_service = instance_double(ImoApiService, send_invitation: :not_valid)
        allow(ImoApiService).to receive(:new).and_return(imo_service)

        expect {
          described_class.perform_async(patient.id)
          described_class.drain
        }.to raise_error(ArgumentError)
        expect(patient.reload.imo_authorization).to be_nil
      end
    end
  end
end
