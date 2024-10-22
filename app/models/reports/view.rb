module Reports
  class View < ActiveRecord::Base
    extend Refreshable

    def self.refresh
      ActiveRecord::Base.transaction do
        puts "Refreshing #{table_name} which is a ctas table" if ctas_table?
        refresh_ctas if ctas_table?
        # puts "Refreshing #{table_name} which is not a ctas table" if materialized?
        refresh_view if ENV["NO_MATVIEW"] == "false"
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
      ActiveRecord::Base.connection.exec_query(
        "COMMENT ON #{"MATERIALIZED" if materialized?} VIEW #{table_name} #{ActiveRecord::Base.sanitize_sql(["IS ?", table_description])}"
      )
    end

    def self.add_column_description(column_description, column_name)
      ActiveRecord::Base.connection.exec_query(
        "COMMENT ON COLUMN #{table_name}.#{column_name} #{ActiveRecord::Base.sanitize_sql(["IS ?", column_description])}"
      )
    end

    def self.materialized?
      # raise NotImplementedError
      if ENV["CTAS"] == "true"
        false
      else
        raise NotImplementedError
      end
    end

    def self.ctas_table?
      ENV["CTAS"] == "true"
    end

    def self.select_sql
      ActiveRecord::Base.connection.execute(
        "SELECT pg_get_viewdef('#{table_name}', true)"
      ).first["pg_get_viewdef"]
    end

    def self.add_indexes(temp_table_name)
      query = <<-SQL
        SELECT indexdef
        FROM pg_indexes
        WHERE tablename = '#{table_name}'
      SQL

      ActiveRecord::Base.connection.execute(query).map { |row| row["indexdef"] }
    end
  end
end
