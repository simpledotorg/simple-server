require "rails_helper"

RSpec.describe RefreshReportingPartitionedTableJob do
  describe "#perform" do
    let(:reporting_month) { "2023-06" }
    let(:table_name) { "reporting_patient_states" }

    it "logs the start of the refresh" do
      allow(ActiveRecord::Base.connection).to receive(:exec_query)
      expect(Rails.logger).to receive(:info).with(
        "Starting refresh for 'reporting_patient_states' for month '2023-06' at #{Time.now.utc}"
      )
      subject.perform(reporting_month, table_name)
    end

    it "executes the correct SQL query" do
      allow(Rails.logger).to receive(:info)
      expect(ActiveRecord::Base.connection).to receive(:exec_query).with(
        "CALL simple_reporting.add_shard_to_table('2023-06', 'reporting_patient_states')"
      )
      subject.perform(reporting_month, table_name)
    end
  end
end
