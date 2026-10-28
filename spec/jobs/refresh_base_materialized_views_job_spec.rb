require "rails_helper"

RSpec.describe RefreshBaseMaterializedViewsJob do
  describe "#perform" do
    it "calls RefreshReportingViews with base views" do
      base_views = [
        "Reports::Month",
        "Reports::Facility",
        "Reports::PatientBloodPressure",
        "Reports::PatientBloodSugar",
        "Reports::OverdueCalls",
        "Reports::PatientVisit",
        "Reports::PatientFollowUp"
      ]

      expect(RefreshReportingViews).to receive(:call).with(views: base_views)
      subject.perform
    end

    it "logs success message" do
      allow(RefreshReportingViews).to receive(:call)
      expect(Rails.logger).to receive(:info).with("Starting refresh of base materialized views after region move")
      expect(Rails.logger).to receive(:info).with("Successfully refreshed base materialized views")
      subject.perform
    end

    it "logs and raises error on failure" do
      allow(RefreshReportingViews).to receive(:call).and_raise(StandardError.new("DB error"))
      expect(Rails.logger).to receive(:error).with("Failed to refresh base materialized views: DB error")
      expect { subject.perform }.to raise_error(StandardError, "DB error")
    end
  end
end
