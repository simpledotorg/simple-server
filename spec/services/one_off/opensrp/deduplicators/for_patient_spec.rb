require "rails_helper"

RSpec.describe OneOff::Opensrp::Deduplicators::ForPatient do
  let!(:existing) { create(:patient) }
  let!(:imported) { create(:patient, :with_dob, :without_address, :without_phone_number) }

  describe "#merge" do
    described_class::CHOOSING_NEW.each do |attr|
      it "prefers the new #{attr}" do
        deduplicator = described_class.new(existing.id, imported.id)
        # deduplicator.should_debug = attr == :full_name
        merged = deduplicator.merge
        expect(merged.send(attr)).to eq(imported.send(attr))
      end
    end

    described_class::CHOOSING_OLD.each do |attr|
      it "prefers the old #{attr}" do
        deduplicator = described_class.new(existing.id, imported.id)
        merged = deduplicator.merge
        expect(merged.send(attr)).to eq(existing.send(attr))
      end
    end

    context "where one of the attributes is null" do
      it "prefers the one that's not null" do
        deduplicator = described_class.new(existing.id, imported.id)
        merged = deduplicator.merge
        expect(merged.address_id).to eq(existing.address_id)
      end
    end

    it "fills out all 'age' columns" do
      # It's fine to do this. This test patient would just grow older with
      # the codebase
      real_age = Date.today.year - imported.date_of_birth.year
      deduplicator = described_class.new(existing.id, imported.id)
      merged = deduplicator.merge
      expect(merged.age).to eq(real_age)
      expect(merged.age_updated_at.strftime("%Y-%m-%d")).to eq(Date.today.to_s)
    end
  end
end
