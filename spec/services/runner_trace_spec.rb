require "rails_helper"

RSpec.describe RunnerTrace, type: :model do
  it "raises an error for confirming Sentry" do
    expect {
      described_class.new.call
    }.to raise_error(RunnerTrace::Error)
  end
end
