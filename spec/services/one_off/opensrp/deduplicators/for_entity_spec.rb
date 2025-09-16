require "rails_helper"

RSpec.describe OneOff::Opensrp::Deduplicators::ForEntity do
  let(:existing) { create(:patient) }
  let(:imported) { create(:patient, :with_dob, :without_address, :without_phone_number) }

  describe "#merge" do
    it "is undefined in base class" do
      deduplicator = described_class.new(existing.id, imported.id)
      expect { deduplicator.merge }.to raise_error("Unimplemented")
    end
  end
end
