require "rails_helper"

RSpec.describe Reports::View, {type: :model, reporting_spec: true} do
  def column_descriptions_sql(table_name)
    <<~SQL
      SELECT a.attname, pg_catalog.col_description(a.attrelid, a.attnum)
      FROM pg_catalog.pg_attribute a
      JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
      WHERE c.relname = '#{table_name}'
        AND pg_catalog.pg_table_is_visible(c.oid)
        AND a.attnum > 0
        AND NOT a.attisdropped;
    SQL
  end

  def table_descriptions_sql(table_name)
    <<~SQL
      SELECT c.relname, d.description
      FROM pg_class c
      JOIN pg_catalog.pg_description d ON c.relfilenode = d.objoid
      WHERE c.relname = '#{table_name}'
        AND d.objsubid = 0;
    SQL
  end

  it "has documentation for all reporting materialized views, and their columns" do
    [Reports::Facility, Reports::Month, Reports::PatientState, Reports::FacilityState].each do |klass|
      klass.add_comments
      expect(ActiveRecord::Base.connection.execute(table_descriptions_sql(klass.table_name)).map { |d| d["description"] }).to all be_present
      expect(ActiveRecord::Base.connection.execute(column_descriptions_sql(klass.table_name)).map { |d| d["col_description"] }).to all be_present
    end
  end

  describe ".fetch_refresh_month_for_date" do
    it "returns current and previous month when date is odd" do
      date_of_refresh = Date.new(2023, 6, 15)
      expect(described_class.fetch_refresh_month_for_date(date_of_refresh)).to eq(Date.new(2023, 5, 1))
    end

    it "returns current month and month offset when date is even" do
      date_of_refresh = Date.new(2023, 6, 16)
      expect(described_class.fetch_refresh_month_for_date(date_of_refresh)).to eq(Date.new(2022, 9, 1))
    end

    it "handles month transitions correctly for odd days" do
      date_of_refresh = Date.new(2023, 1, 1)
      expect(described_class.fetch_refresh_month_for_date(date_of_refresh)).to eq(Date.new(2022, 12, 1))
    end
  end

  describe ".get_refresh_months" do
    context "when refresh frequency is not set" do
      before { ENV.delete("REPORTING_REFRESH_FREQUENCY") }

      it "defaults to daily logic" do
        travel_to(Date.new(2025, 9, 24)) do
          expect(described_class.get_refresh_months).to eq([Date.new(2025, 9, 1), Date.new(2024, 8, 1)])
        end
      end
    end

    context "when refresh frequency is set to weekly" do
      before { ENV["REPORTING_REFRESH_FREQUENCY"] = "weekly" }

      it "returns the correct refresh months" do
        travel_to(Date.new(2025, 9, 24)) do
          expected_months = [Date.new(2025, 8, 1), Date.new(2024, 11, 1), Date.new(2024, 10, 1), Date.new(2024, 9, 1), Date.new(2024, 8, 1), Date.new(2025, 9, 1)]
          expect(described_class.get_refresh_months).to match_array(expected_months)
        end
      end
    end

    context "when refresh frequency is set to something else" do
      before { ENV["REPORTING_REFRESH_FREQUENCY"] = "something else" }

      it "defaults to daily logic" do
        travel_to(Date.new(2025, 9, 24)) do
          expect(described_class.get_refresh_months).to eq([Date.new(2025, 9, 1), Date.new(2024, 8, 1)])
        end
      end
    end
  end

  describe "#partitioned_refresh" do
    let(:refresh_month) { Date.new(2024, 6, 1) }

    it "executes the correct SQL to refresh the partition" do
      [Reports::PatientState, Reports::FacilityMonthlyFollowUpAndRegistration].each do |klass|
        expect(ActiveRecord::Base.connection).to receive(:exec_query).with(
          "CALL simple_reporting.add_shard_to_table('#{refresh_month}', '#{klass.table_name}')"
        )

        klass.partitioned_refresh(refresh_month)
      end
    end
  end
end
