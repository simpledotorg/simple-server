# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordCounterJob, type: :job do
  it "works" do
    described_class.new.perform
  end
end
