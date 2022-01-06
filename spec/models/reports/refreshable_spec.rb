# frozen_string_literal: true

require "rails_helper"

module Reports
  class FakeMatView
    extend Refreshable

    def self.table_name
      "fake_mat_view"
    end
  end
end

RSpec.describe Reports::Refreshable do
  describe "refresh?" do
    after do
      ENV.delete("REFRESH_MATVIEWS_CONCURRENTLY")
    end

    it "calls Scenic's refresh method" do
      expect(Scenic.database).to receive(:refresh_materialized_view).with("fake_mat_view", anything)
      Reports::FakeMatView.refresh
    end

    it "sets concurrency to true by default" do
      expect(Scenic.database).to receive(:refresh_materialized_view).with("fake_mat_view", concurrently: true, cascade: false)
      Reports::FakeMatView.refresh
    end

    it "concurrency can be disabled via ENV var" do
      ENV["REFRESH_MATVIEWS_CONCURRENTLY"] = "false"
      expect(Scenic.database).to receive(:refresh_materialized_view).with("fake_mat_view", concurrently: false, cascade: false)
      Reports::FakeMatView.refresh
    end
  end
end
