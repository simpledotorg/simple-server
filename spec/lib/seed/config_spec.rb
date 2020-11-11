require "rails_helper"

RSpec.describe Seed::Config do
  it "fails unknown SimpleServer.env" do
    expect(SimpleServer).to receive(:env).and_return("production").at_least(1).times
    expect {
      Seed::Config.new
    }.to raise_error(ArgumentError)
  end

  it "sets test_mode to true when RAILS_ENV is test" do
    config = Seed::Config.new
    expect(config.test_mode).to be_truthy
  end

  it "sets test_mode to false for every other RAILS_ENV" do
    expect(Rails.env).to receive(:test?).and_return(false)
    config = Seed::Config.new
    expect(config.test_mode).to be_falsey
  end

  it "uses ENV var values from fast config for test" do
    config = Seed::Config.new
    expect(config.scale_factor).to eq(0.1)
    expect(config.number_of_facility_groups).to eq(2)
    expect(config.max_number_of_facilities_per_facility_group).to eq(4)
    expect(config.max_patients_to_create[:community]).to eq(3)
    expect(config.max_patients_to_create[:large]).to eq(8)
  end
end