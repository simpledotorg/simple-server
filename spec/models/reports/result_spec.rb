require "rails_helper"

describe Reports::Result, type: :model do
  let(:july_2018) { Period.month("July 1 2018") }
  let(:may_2020) { Period.month("May 1 2020") }
  let(:june_2020) { Period.month("June 1 2020") }
  let(:sept_2020) { Period.month("September 1 2020") }

  let(:range) { (july_2018..june_2020) }
  let(:region) { create(:facility) }

  before do
    Timecop.travel(june_2020.to_date)
  end

  it "has convenience methods" do
    result = Reports::Result.new(region: region, period_type: :month)
    result[:uncontrolled_patients][june_2020] = 30
    result[:controlled_patients][june_2020] = 100
    expect(result.uncontrolled_patients).to be(result[:uncontrolled_patients])
    expect(result.controlled_patients).to be(result[:controlled_patients])
  end

  it "has setters" do
    result = Reports::Result.new(region: region, period_type: :month)
    hsh = {june_2020 => 30}
    result.uncontrolled_patients = hsh
    expect(result.uncontrolled_patients).to eq(hsh)
  end

  it "can return report data that limits results to the range requested" do
    june_2000 = Period.month("June 1 2000")
    result = Reports::Result.new(region: region, period_type: :month)
    result[:uncontrolled_patients][june_2000] = 50
    result[:uncontrolled_patients][june_2020] = 100
    result[:uncontrolled_patients][sept_2020] = 100
    data = result.report_data_for(range)

    expect(data[:uncontrolled_patients][june_2020]).to eq(100)
    expect(data[:uncontrolled_patients].key?(june_2000)).to be_falsey
    expect(data[:uncontrolled_patients][june_2020]).to eq(100)
    expect(data[:uncontrolled_patients].key?(sept_2020)).to be_falsey
    expect(data[:uncontrolled_patients][july_2018]).to eq(0)
    expect(data[:uncontrolled_patients][sept_2020]).to eq(0)
  end
end
