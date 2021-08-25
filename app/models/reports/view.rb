module Reports
  class View < ActiveRecord::Base
    def self.refresh
      ActiveRecord::Base.transaction do
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
        "COMMENT ON VIEW #{table_name} #{ActiveRecord::Base.sanitize_sql(["IS ?", table_description])}"
      )
    end

    def self.add_column_description(column_description, column_name)
      ActiveRecord::Base.connection.exec_query(
        "COMMENT ON COLUMN #{table_name}.#{column_name} #{ActiveRecord::Base.sanitize_sql(["IS ?", column_description])}"
      )
    end
  end
end
