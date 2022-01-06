# frozen_string_literal: true

require "rails_helper"

RSpec.describe RunnerTrace, type: :model do
  it "raises an error for confirming Sentry" do
    expect(Sentry).to receive(:capture_exception)
    expect {
      described_class.new.call
    }.to raise_error(RunnerTrace::Error, "Runner trace error")
  end
end
