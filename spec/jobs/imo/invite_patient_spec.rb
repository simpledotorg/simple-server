require "rails_helper"

RSpec.describe Imo::InvitePatient, type: :job do
  describe "#perform" do
    context "with feature flag turned off" do
      it "does nothing" do
        patient = create(:patient)
        allow_any_instance_of(ImoApiService).to receive(:invite).and_return("invited")

        expect {
          described_class.perform_async(patient.id)
          described_class.drain
        }.not_to change { ImoAuthorization.count }
      end
    end

    context "with feature flag turned on" do
      before { Flipper.enable(:imo_messaging) }

      it "raises an error when the patient id is not found" do
        expect {
          described_class.perform_async("fake")
          described_class.drain
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "creates an ImoAuthorization with 'invited' status when invitation is sent" do
        patient = create(:patient)
        allow_any_instance_of(ImoApiService).to receive(:invite).and_return(:invited)

        expect {
          described_class.perform_async(patient.id)
          described_class.drain
        }.to change { ImoAuthorization.count }.from(0).to(1)
        imo_auth = ImoAuthorization.last
        expect(imo_auth.status).to eq("invited")
        expect(imo_auth.patient_id).to eq(patient.id)
      end

      it "creates an ImoAuthorization with 'no_imo_account' status when invited user has no Imo account" do
        patient = create(:patient)
        allow_any_instance_of(ImoApiService).to receive(:invite).and_return(:no_imo_account)

        expect {
          described_class.perform_async(patient.id)
          described_class.drain
        }.to change { ImoAuthorization.count }.from(0).to(1)
        imo_auth = ImoAuthorization.last
        expect(imo_auth.status).to eq("no_imo_account")
        expect(imo_auth.patient_id).to eq(patient.id)
      end

      it "does not create an ImoAuthorization when invitation fails" do
        patient = create(:patient)
        allow_any_instance_of(ImoApiService).to receive(:invite).and_raise("error")

        expect {
          described_class.perform_async(patient.id)
          described_class.drain rescue RuntimeError
        }.not_to change { ImoAuthorization.count }
      end
    end
  end
end
