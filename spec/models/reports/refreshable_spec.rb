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

    it "sets work mem when the env var is set and the Flipper flag is enabled" do
      Flipper.enable(:optimize_work_mem)
      ENV["REFRESH_WORK_MEM"] = "1GB"
      allow(Scenic.database).to receive(:refresh_materialized_view).with("fake_mat_view", concurrently: true, cascade: false)

      Reports::FakeMatView.refresh
      expect(ActiveRecord::Base.connection.execute("SHOW work_mem").first["work_mem"]).to eq("1GB")
    end

    it "does not set work mem when the env var is not set" do
      Flipper.enable(:optimize_work_mem)
      ENV.delete("REFRESH_WORK_MEM")
      allow(Scenic.database).to receive(:refresh_materialized_view).with("fake_mat_view", concurrently: true, cascade: false)

      expect(ActiveRecord::Base.connection).not_to receive(:execute).with("SET LOCAL work_mem TO '1GB'")
      Reports::FakeMatView.refresh
    end
  end
end
