module ExportReportingSchema
  def self.export_all_tables
    [Reports::PatientState].each do |klass|
      # export detailed csv
      detail_filename = File.join(Dir.getwd, "public", "documents", "#{klass.table_name}_detail.csv")
      ActiveRecord::Base.connection.execute(export_sql(klass.table_name, detail_filename))

      # export summary csv
      summary_filename = File.join(Dir.getwd, "public", "documents", "#{klass.table_name}_summary.csv")
      summary_columns = column_metadata(klass.table_name).select { |_, info| info["reference_category"] == "summary" }.keys
      ActiveRecord::Base.connection.execute(export_sql(klass.table_name, summary_filename, summary_columns))
    end
  end

  def self.column_metadata(table_name)
    YAML.load_file("config/schema_descriptions.yml")[table_name]["columns"]
  end

  def self.export_sql(table_name, filename, column_names = [])
    <<SQL
    COPY (
      WITH schema_descriptions AS (
        SELECT c.relname                                        AS table_name,
               a.attname                                        AS column_name,
               pg_catalog.format_type(a.atttypid, a.atttypmod)  AS data_type,
               pg_catalog.col_description(a.attrelid, a.attnum) AS description
        FROM pg_catalog.pg_attribute a
        JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
        WHERE pg_catalog.pg_table_is_visible(c.oid)
        AND a.attnum > 0
        AND NOT a.attisdropped
      )

      SELECT column_name, data_type, description
      FROM schema_descriptions
      WHERE table_name = '#{table_name}'
      #{column_selection_sql(column_names)}
    )
    TO '#{filename}'
    WITH CSV DELIMITER ',' HEADER
SQL
  end

  def self.column_selection_sql(column_names)
    return "" if column_names.empty?
    column_list = column_names.map { |s| "'#{s}'" }.join(",")
    "AND column_name in (#{column_list})"
  end
end
