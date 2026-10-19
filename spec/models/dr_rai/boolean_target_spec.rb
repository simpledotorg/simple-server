require "rails_helper"

RSpec.describe DrRai::BooleanTarget, type: :model do
  describe "type" do
    it 'should be "Boolean"' do
      expect(DrRai::BooleanTarget.new.type).to eq "DrRai::BooleanTarget"
    end
  end

  describe "completed_at" do
    let(:target) { DrRai::BooleanTarget.create!(period: "Q1-2025", completed: false, indicator: DrRai::CustomIndicator.create) }

    it "marks the target completed with the time it was completed" do
      Timecop.freeze(Time.zone.parse("August 7 2026 10:00")) { target.update!(completed: true) }

      expect(target.reload.completed).to be true
      expect(target.completed_at).to eq Time.zone.parse("August 7 2026 10:00")
    end

    it "keeps the original completion time when completed again" do
      Timecop.freeze(Time.zone.parse("August 7 2026 10:00")) { target.update!(completed: true) }
      Timecop.freeze(Time.zone.parse("August 9 2026 10:00")) { target.update!(completed: true) }

      expect(target.reload.completed_at).to eq Time.zone.parse("August 7 2026 10:00")
    end

    it "marks a completed target incomplete and clears the completion time" do
      target.update!(completed: true)
      target.update!(completed: false)

      expect(target.reload.completed).to be false
      expect(target.completed_at).to be_nil
    end
  end
end
