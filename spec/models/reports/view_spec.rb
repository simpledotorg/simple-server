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

  describe ".get_refresh_months" do
    it "returns current and previous month when current day is odd" do
      travel_to Date.new(2023, 6, 15) do
        expected_months = [Date.new(2023, 6, 1), Date.new(2023, 5, 1)]
        expect(described_class.get_refresh_months).to eq(expected_months)
      end
    end

    it "returns current month and month offset when current day is even" do
      travel_to Date.new(2023, 6, 16) do
        expected_months = [Date.new(2023, 6, 1), Date.new(2022, 9, 1)]
        expect(described_class.get_refresh_months).to eq(expected_months)
      end
    end

    it "handles month transitions correctly for odd days" do
      travel_to Date.new(2023, 1, 1) do
        expected_months = [Date.new(2023, 1, 1), Date.new(2022, 12, 1)]
        expect(described_class.get_refresh_months).to eq(expected_months)
      end
    end
  end
end
