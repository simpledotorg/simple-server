require "rails_helper"

describe "opensrp:export" do
  include_context "rake"

  let(:test_config_file) { "spec/support/fixtures/test-export-config.yml" }

  it "should reqiure a config file" do
    expect(YAML).to receive(:load_file).with(test_config_file).and_call_original
    subject.invoke(test_config_file, "output.json")
  end
end
