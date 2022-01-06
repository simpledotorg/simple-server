# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::Config do
  before do
    # We need to clear this, otherwise tests that depend on them will have weird side
    # effects hanging around from previous tests
    ENV.delete("SEED_TEST_MODE")
  end

  after do
    # We want to make sure other tests have the correct test ENV values, so overload
    Dotenv.overload!(".env.seed.test")
  end

  it "fails for unknown SimpleServer.env" do
    expect(SimpleServer).to receive(:env).and_return("production").at_least(1).times
    expect {
      Seed::Config.new
    }.to raise_error(ArgumentError)
  end

  it "sets test_mode to true when SIMPLE_SERVER_ENV is test" do
    config = Seed::Config.new
    expect(config.test_mode).to be_truthy
  end

  it "sets test_mode to false for every other SIMPLE_SERVER_ENV" do
    expect(SimpleServer).to receive(:env).and_return("development").at_least(1).times
    config = Seed::Config.new
    expect(config.test_mode).to be_falsey
  end

  it "uses ENV var values from fast config for test" do
    config = Seed::Config.new
    expect(config.scale_factor).to eq(1.0)
    expect(config.number_of_facility_groups).to eq(2)
    expect(config.max_number_of_facilities_per_facility_group).to eq(4)
    expect(config.max_patients_to_create[:community]).to eq(3)
    expect(config.max_patients_to_create[:large]).to eq(8)
  end

  it "uses ENV var values from the correct config for different environments" do
    mapping = {
      "test" => "test",
      "android_review" => "empty",
      "development" => "small",
      "review" => "small",
      "demo" => "medium",
      "sandbox" => "large"
    }

    mapping.each do |environment, seed|
      allow(SimpleServer).to receive(:env).and_return(environment)

      expect(Seed::Config.new.type).to eq(seed)
    end
  end
end
