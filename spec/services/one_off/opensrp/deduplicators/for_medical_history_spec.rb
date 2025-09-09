require "rails_helper"

TIME_FIELDS = %i[
  created_at
  updated_at
  device_created_at
  device_updated_at
  recorded_at
]

RSpec.describe OneOff::Opensrp::Deduplicators::ForMedicalHistory do
  let(:existing) { create(:patient) }
  let(:imported) { create(:patient, :with_dob, :without_address, :without_phone_number) }

  describe "#merge" do
    described_class::CHOOSING_NEW.reject { |k| TIME_FIELDS.include?(k) }.each do |attr|
      it "prefers the new #{attr}" do
        deduplicator = described_class.new(existing.id, imported.id)
        merged = deduplicator.merge
        expect(merged.send(attr)).to eq(imported.medical_history.send(attr))
      end
    end

    described_class::CHOOSING_OLD.reject { |k| TIME_FIELDS.include?(k) }.each do |attr|
      it "prefers the old #{attr}" do
        deduplicator = described_class.new(existing.id, imported.id)
        merged = deduplicator.merge
        expect(merged.send(attr)).to eq(existing.medical_history.send(attr))
      end
    end
  end
end
