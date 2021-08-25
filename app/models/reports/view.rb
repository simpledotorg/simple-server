module Reports
  class View < ActiveRecord::Base
    def self.refresh
      ActiveRecord::Base.transaction do
        if materialized?
          ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Period::REPORTING_TIME_ZONE}'")
          Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
        end
        add_comments
      end
    end

    def self.add_comments
      table_comments = YAML.load_file("config/schema_descriptions.yml")[table_name]
      return unless table_comments.present?
      add_table_description(table_name, table_comments["description"])
      table_comments["columns"].each do |column_name, column_description|
        add_column_description(column_description, column_name)
      end
    end

    def self.add_table_description(table_name, table_description)
      if materialized?
        ActiveRecord::Base.connection.exec_query(
          "COMMENT ON MATERIALIZED VIEW #{table_name} #{ActiveRecord::Base.sanitize_sql(["IS ?", table_description])}"
        )
      else
        ActiveRecord::Base.connection.exec_query(
          "COMMENT ON VIEW #{table_name} #{ActiveRecord::Base.sanitize_sql(["IS ?", table_description])}"
        )
      end
    end

    def self.add_column_description(column_description, column_name)
      ActiveRecord::Base.connection.exec_query(
        "COMMENT ON COLUMN #{table_name}.#{column_name} #{ActiveRecord::Base.sanitize_sql(["IS ?", column_description])}"
      )
    end

    def self.materialized?
      raise NotImplementedError
    end
  end
end
