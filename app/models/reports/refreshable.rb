module Reports
  module Refreshable
    # Refresh a materialized view.
    #
    # By default this will be done within a transaction, unless the `transaction` arg is set to false
    def refresh(transaction: true)
      refresh_ctas if ctas_table?
      return refresh_view unless transaction
      ActiveRecord::Base.transaction do
        refresh_view
      end
    end

    def ctas_table?
      false
    end

    def select_sql
      raise NotImplementedError, "#{name} must implement select_sql method for CTAS refresh"
    end

    def add_indexes(temp_table_name)
      raise NotImplementedError, "#{name} must implement add_indexes method for CTAS refresh"
    end

    def validate_new_table(temp_table_name)
      raise NotImplementedError, "#{name} must implement validate_new_table method for CTAS refresh"
    end

    private

    def refresh_ctas
      temp_table_name = "#{table_name}_new"
      ActiveRecord::Base.connection.execute(<<-SQL)
        CREATE TABLE #{temp_table_name} AS
        #{select_sql}
      SQL

      add_indexes(temp_table_name)

      ActiveRecord::Base.connection.execute(<<-SQL)
        ALTER TABLE IF EXISTS #{table_name}_ctas RENAME TO #{table_name}_old;
        ALTER TABLE #{temp_table_name} RENAME TO #{table_name}_ctas;
        DROP TABLE IF EXISTS #{table_name}_old;
      SQL
    end

    def refresh_view
      ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Period::REPORTING_TIME_ZONE}'")
      Scenic.database.refresh_materialized_view(table_name, concurrently: refresh_concurrently?, cascade: false)
    end

    def refresh_concurrently?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("REFRESH_MATVIEWS_CONCURRENTLY", true))
    end
  end
end
