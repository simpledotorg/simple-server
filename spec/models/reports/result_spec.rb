require "rails_helper"

describe Reports::Result, type: :model do
  let(:july_2018) { Period.month("July 1 2020")}
  let(:may_2020) { Period.month("May 1 2020")}
  let(:june_2020) { Period.month("June 1 2020")}

  let(:range) { (july_2018..june_2020) }

  it "has convenience methods" do
    result = Reports::Result.new(range)
    result[:uncontrolled_patients][june_2020] = 30
    result[:controlled_patients][june_2020] = 100
    expect(result.uncontrolled_patients_for(june_2020)).to eq(30)
    expect(result.uncontrolled_patients).to be(result[:uncontrolled_patients])
    expect(result.controlled_patients_for(june_2020)).to eq(100)
    expect(result.controlled_patients).to be(result[:controlled_patients])
  end

  it "has setters" do
    result = Reports::Result.new(range)
    hsh = { june_2020 => 30 }
    result.uncontrolled_patients = hsh
    expect(result.uncontrolled_patients).to eq(hsh)
  end

  it "can get last value for the data" do
    result = Reports::Result.new(range)
    result[:uncontrolled_patients][may_2020] = 20
    result[:uncontrolled_patients][june_2020] = 30
    expect(result.last_value(:uncontrolled_patients)).to eq(30)
  end
end