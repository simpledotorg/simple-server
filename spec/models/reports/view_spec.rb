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
end
