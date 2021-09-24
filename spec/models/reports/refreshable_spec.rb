require "rails_helper"

RSpec.describe Reports::Refreshable do
  class FakeMatView
    extend Reports::Refreshable
    def self.table_name
      "fake_mat_view"
    end
  end

  describe "refresh?" do
    after do
      ENV.delete("REFRESH_MATVIEWS_CONCURRENTLY")
    end

    it "calls Scenic's refresh method" do
      expect(Scenic.database).to receive(:refresh_materialized_view).with("fake_mat_view", anything)
      FakeMatView.refresh
    end

    it "sets concurrency to true by default" do
      expect(Scenic.database).to receive(:refresh_materialized_view).with("fake_mat_view", concurrently: true, cascade: false)
      FakeMatView.refresh
    end

    it "concurrency can be disabled via ENV var" do
      ENV["REFRESH_MATVIEWS_CONCURRENTLY"] = "false"
      expect(Scenic.database).to receive(:refresh_materialized_view).with("fake_mat_view", concurrently: false, cascade: false)
      FakeMatView.refresh
    end
  end
end
