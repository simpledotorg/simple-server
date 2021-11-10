require "rails_helper"

RSpec.describe Imo::InviteUnsubscribedPatients, type: :job do
  let(:date) { "1-1-2020".to_date }

  describe "#perform" do
    context "with feature flag turned off" do
      it "does nothing" do
        create(:patient)
        expect(Imo::InvitePatient).not_to receive(:perform_at)
        described_class.perform_async(Patient.count)
        described_class.drain
      end
    end

    context "with feature flag turned on" do
      before { Flipper.enable(:imo_messaging) }

      it "queues an Imo::InvitePatient job for patients who have no ImoAuthorization" do
        patient = create(:patient)
        Timecop.freeze(date) do
          expect(Imo::InvitePatient).to receive(:perform_at).with(date, patient.id)
          described_class.perform_async(Patient.count)
          described_class.drain
        end
      end

      it "queues an Imo::InvitePatient job for non-subscribed patients who were invited over 6 months ago" do
        patient = create(:patient)
        create(:imo_authorization, patient: patient, status: "invited", last_invited_at: date - 7.months)
        Timecop.freeze(date) do
          expect(Imo::InvitePatient).to receive(:perform_at).with(date, patient.id)
          described_class.perform_async(Patient.count)
          described_class.drain
        end
      end

      it "excludes patients who were invited less than six months ago" do
        patient = create(:patient)
        create(:imo_authorization, patient: patient, status: "invited", last_invited_at: 1.day.ago)
        expect(Imo::InvitePatient).not_to receive(:perform_at)
        described_class.perform_async(Patient.count)
        described_class.drain
      end

      it "excludes patients who have been successfully subscribed" do
        patient = create(:patient)
        create(:imo_authorization, patient: patient, status: "subscribed", last_invited_at: 1.year.ago)
        expect(Imo::InvitePatient).not_to receive(:perform_at)
        described_class.perform_async(Patient.count)
        described_class.drain
      end

      it "excludes non-contactable patients" do
        patient = create(:patient)
        phone = patient.phone_numbers.last
        phone.update!(phone_type: nil)
        expect(Imo::InvitePatient).not_to receive(:perform_at)
        described_class.perform_async(Patient.count)
        described_class.drain
      end

      it "excludes LTFU patients" do
        create(:patient, recorded_at: 2.years.ago)
        expect(Imo::InvitePatient).not_to receive(:perform_at)
        described_class.perform_async(Patient.count)
        described_class.drain
      end

      it "invites only the selected number of patients" do
        patient_1 = create(:patient)
        patient_2 = create(:patient)

        Timecop.freeze(date) do
          expect(Imo::InvitePatient).to receive(:perform_at).exactly(1).time
          described_class.perform_async(1)
          described_class.drain
        end
      end
    end
  end
end
