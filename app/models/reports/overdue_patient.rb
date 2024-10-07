module Reports
  class OverduePatient < Reports::View
    self.table_name = "reporting_overdue_patients"
    belongs_to :patient

    def self.materialized?
      true
    end

    def self.ctas_table?
      false
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
