require "rails_helper"

describe "opensrp:export" do
  include_context "rake"

  TEST_CONFIG = 'spec/support/fixtures/test-export-config.yml'

  it "should reqiure a config file" do
    expect(YAML).to receive(:load_file).with(TEST_CONFIG).and_call_original
    subject.invoke(TEST_CONFIG, 'output.json')
  end
end
