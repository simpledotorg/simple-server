require "rails_helper"

RSpec.describe DrRai::BpFudgingIndicator, type: :model do
  describe "ui copy" do
    subject { described_class.new }

    it { expect(subject.display_name).to eq("BP Fudging") }
    it { expect(subject.target_type_frontend).to eq("custom") }
    it { expect(subject.numerator_key).to eq(:numerator) }
    it { expect(subject.denominator_key).to eq(:denominator) }
    it { expect(subject.action_passive).to eq("fudged") }
    it { expect(subject.action_active).to eq("Fudge") }
    it { expect(subject.unit).to eq("bps") }
  end

  describe "datasource" do
    let(:data_class) { DrRai::Data::BpFudging }
    let(:the_region) { double("Region") }
    it "delegates to the data model" do
      allow(the_region).to receive(:name).and_return("abv")
      expect(data_class).to receive(:chartable).and_return({"abv" => {}})
      subject.datasource the_region
    end
  end
end
