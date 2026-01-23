module Reports
  class View < ActiveRecord::Base
    extend Refreshable

    def self.refresh
      ActiveRecord::Base.transaction do
        refresh_view if materialized?
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
      raise NotImplementedError
    end

    def self.get_refresh_months
      current_date = Date.today
      if ENV["REPORTING_REFRESH_FREQUENCY"]&.downcase == "weekly"
        start_date = current_date - 7.days
        refresh_months = []
        (start_date..current_date).each { |refresh_date| refresh_months << fetch_refresh_month_for_date(refresh_date) }
        refresh_months << current_date.beginning_of_month
        refresh_months.uniq
      else
        [current_date.beginning_of_month, fetch_refresh_month_for_date(current_date)].uniq
      end
    end

    def self.fetch_refresh_month_for_date(date_of_refresh)
      month_of_refresh = date_of_refresh.beginning_of_month
      day_of_month = date_of_refresh.day
      month_offset = (day_of_month / 2) + 1
      day_of_month.odd? ? month_of_refresh.prev_month : (month_of_refresh - month_offset.month)
    end

    def self.partitioned_refresh(refresh_month)
      ActiveRecord::Base.connection.exec_query(
        "CALL simple_reporting.add_shard_to_table('#{refresh_month}', '#{table_name}')"
      )
    end
  end
end
