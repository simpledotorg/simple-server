require 'rails_helper'

RSpec.describe SetRiskLevel do
  it "sets risk level if nil" do
    patient = create(:patient)
    expect(patient.risk_level).to be_nil
    SetRiskLevel.call(patient)
    expect(patient.risk_level).to_not be_nil
  end

  it "does nothing if risk level has not changed" do
    patient = create(:patient, risk_level: 1)
    expect(patient.risk_level).to eq(1)

    expect(patient).to receive(:update).never

    SetRiskLevel.call(patient)
    expect(patient.risk_level).to eq(1)
  end

  it "has nested result class" do
    p SetRiskLevel::Result
  end
end