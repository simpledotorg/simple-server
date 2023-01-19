require "rails_helper"
require "tasks/scripts/pre_fill_monthly_screening_reports"

RSpec.describe PreFillMonthlyScreeningReports do
  describe "#call" do
    it "pre-fills monthly screening reports for previous month" do
    end

    it "ignores existing monthly screening reports" do
    end

    it "links pre-filled reports to last active questionnaire" do
    end

    it "ignores non-monthly screening reports for idempotency check" do
    end
  end
end
