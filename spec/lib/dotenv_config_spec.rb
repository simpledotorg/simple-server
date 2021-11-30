require "rails_helper"

RSpec.describe "config loading via Dotenv" do
  it ".env.defaults are loaded" do
    expect(ENV["DUMMY_VALUE_FOR_TEST"]).to eq("this-is-a-test")
  end

  it ".env.defaults will not overwrite ENV vars already set" do
    ENV.delete("DUMMY_VALUE_FOR_TEST")
    ENV["DUMMY_VALUE_FOR_TEST"] = "set-first"
    DotenvLoad.load
    expect(ENV["DUMMY_VALUE_FOR_TEST"]).to eq("set-first")
  end
end