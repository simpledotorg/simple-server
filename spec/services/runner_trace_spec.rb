require "rails_helper"

RSpec.describe RunnerTrace, type: :model do
  it "raises an error for confirming Sentry" do
    expect(Sentry).to receive(:capture_exception)
    described_class.new.call
  end
end
