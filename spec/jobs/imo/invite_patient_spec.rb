# frozen_string_literal: true

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

      it "creates an ImoAuthorization using the status returned by the imo service" do
        current_date = "1-1-2020".to_date
        patient = create(:patient)
        imo_service = instance_double(ImoApiService, send_invitation: :invited)
        allow(ImoApiService).to receive(:new).and_return(imo_service)

        Timecop.freeze(current_date) do
          expect {
            described_class.perform_async(patient.id)
            described_class.drain
          }.to change { patient.reload.imo_authorization }.from(nil)
          expect(patient.imo_authorization.status).to eq("invited")
          expect(patient.imo_authorization.last_invited_at).to eq(current_date)
        end
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

      it "updates the patient's imo auth if they have one" do
        patient = create(:patient)
        current_date = "1-1-2020".to_date
        older_date = current_date - 6.months
        imo_auth = create(:imo_authorization, status: :no_imo_account, patient: patient, last_invited_at: older_date)
        imo_service = instance_double(ImoApiService, send_invitation: :invited)
        allow(ImoApiService).to receive(:new).and_return(imo_service)

        Timecop.freeze(current_date) do
          expect {
            described_class.perform_async(patient.id)
            described_class.drain
          }.to change { imo_auth.reload.status }.from("no_imo_account").to("invited")
            .and change { imo_auth.last_invited_at }.from(older_date).to(current_date)
        end
      end
    end
  end
end
