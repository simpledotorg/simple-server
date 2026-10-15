require "rails_helper"

RSpec.describe DrRai::CustomIndicator, type: :model do
  subject { described_class.new }

  let(:region) { setup_district_with_facilities[:region] }

  it { expect(subject.display_name).to eq("Create my own") }
  it { expect(subject.target_type_frontend).to eq("boolean") }
  it { expect(subject.target_type).to eq("DrRai::BooleanTarget") }
  it { expect(subject.tooltip).to eq("To track something not listed, select this option to create your own") }

  it "is supported in every region" do
    expect(subject.is_supported?(region)).to be true
  end

  it "has no data" do
    expect(subject.numerator(region, Period.current.to_quarter_period)).to be_nil
    expect(subject.denominator(region, Period.current.to_quarter_period)).to be_nil
  end

  it "allows any number of action plans in a quarter" do
    indicator = described_class.create
    period = Period.new(type: :quarter, value: "Q1-2025")
    create(:action_plan, region: region, dr_rai_indicator: indicator,
      dr_rai_target: create(:target, :boolean, period: "Q1-2025", indicator: indicator))

    expect(indicator.has_action_plans?(region, period)).to be false
  end
end
