require "rails_helper"

RSpec.describe Reports::Matview, {type: :model, reporting_spec: true} do
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

  def column_descriptions(table_name)
    ActiveRecord::Base.connection.execute(column_descriptions_sql(table_name))
  end

  it "has documentation for all reporting materialized views, and their columns" do
    [Reports::PatientState].each do |klass|
      klass.add_comments
      expect(ActiveRecord::Base)
      expect(ActiveRecord::Base.connection.execute(column_descriptions_sql(klass.table_name)).map { |d| d["col_description"] }).to all be_present
    end
  end
end
