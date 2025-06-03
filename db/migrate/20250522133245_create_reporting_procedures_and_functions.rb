class CreateReportingProceduresAndFunctions < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS simple_reporting.simple_reporting_runs (
        run_key UUID,
        action_name VARCHAR(255),
        target_date date,
        start_date TIMESTAMP DEFAULT now(), 
        end_date TIMESTAMP,
        duration_in_second NUMERIC(18,3) 
          GENERATED ALWAYS AS (
            EXTRACT(EPOCH FROM end_date - start_date)
          ) STORED,
        action_status VARCHAR(255),
        sql_state VARCHAR(255),
        sql_error_message VARCHAR(255),
        PRIMARY KEY (run_key, action_name)
      );

      CREATE OR REPLACE PROCEDURE simple_reporting.monitored_execute(
        run_id UUID,
        action_key TEXT,
        target_month_date DATE,
        target_query TEXT
      )
      LANGUAGE plpgsql
      AS $$
      DECLARE
        internal_start_date TIMESTAMP := clock_timestamp();
      BEGIN
        RAISE NOTICE 'EXECUTING <%>: %', action_key, target_query;
        BEGIN
          EXECUTE target_query;

          INSERT INTO simple_reporting.simple_reporting_runs (run_key, action_name, target_date, start_date, end_date, action_status)
          VALUES (run_id, action_key, target_month_date, internal_start_date, clock_timestamp(), 'OK');

        EXCEPTION WHEN OTHERS THEN
          INSERT INTO simple_reporting.simple_reporting_runs (run_key, action_name, target_date, start_date, end_date, action_status, sql_state, sql_error_message)
          VALUES (run_id, action_key, target_month_date, internal_start_date, clock_timestamp(), 'ERROR', SQLSTATE, SQLERRM);
        END;
      END;
      $$;

      CREATE OR REPLACE PROCEDURE simple_reporting.generate_and_attach_shard_to_table(start_date DATE, table_name TEXT)
      LANGUAGE plpgsql
      AS $$
      DECLARE
        target_reference_date DATE := date_trunc('month', start_date)::DATE;
        target_table_key TEXT := TO_CHAR(target_reference_date, 'YYYYMMDD');
        target_to_date TEXT := 'date_trunc(''month'', TO_DATE(''' || target_table_key || ''', ''YYYYMMDD''))::date';
        target_table_name TEXT := 'simple_reporting.'|| table_name || '_' || target_table_key;
        partition_drop_monitoring_key TEXT := UPPER(table_name) || '_PARTITION_DROP';
        ctas_monitoring_key TEXT := UPPER(table_name) || '_PARTITION_CTAS';
        partition_check_monitoring_key TEXT := UPPER(table_name) || '_PARTITION_CHECK';
        partition_attach_monitoring_key TEXT := UPPER(table_name) || '_PARTITION_SHARD';

        drop_statement TEXT := 'DROP TABLE IF EXISTS ' || target_table_name || ';';

        ctas_statement TEXT := 
            'CREATE TABLE ' || target_table_name ||
            ' AS SELECT * FROM simple_reporting.' || table_name || '_table_function(' ||
            target_to_date || ');';

        check_statement TEXT := 
            'ALTER TABLE ' || target_table_name ||
            ' ADD CONSTRAINT ' || table_name || '_month_date_shard_check CHECK (month_date = ' ||
            target_to_date || ');';

        shard_statement TEXT := 
            'ALTER TABLE simple_reporting.' || table_name || ' ATTACH PARTITION ' ||
            target_table_name || ' FOR VALUES IN (' || target_to_date || ');';

        run_key UUID := gen_random_uuid();
      BEGIN
        CALL simple_reporting.monitored_execute(run_key, partition_drop_monitoring_key, target_reference_date, drop_statement);
        CALL simple_reporting.monitored_execute(run_key, ctas_monitoring_key, target_reference_date, ctas_statement);
        CALL simple_reporting.monitored_execute(run_key, partition_check_monitoring_key, target_reference_date, check_statement);
        CALL simple_reporting.monitored_execute(run_key, partition_attach_monitoring_key, target_reference_date, shard_statement);
      END;
      $$;

      CREATE OR REPLACE PROCEDURE simple_reporting.add_shard_to_table(target_month_date DATE, table_name TEXT)
      LANGUAGE plpgsql
      AS $$
      DECLARE
        monitoring_key TEXT := UPPER(table_name) || '_PARTITION_ALL';
        call_internal_statement TEXT ;
        
      BEGIN
        call_internal_statement := 
          'CALL simple_reporting.generate_and_attach_shard_to_table(TO_DATE(''' 
          || TO_CHAR(target_month_date, 'YYYY-MM') 
          || ''', ''YYYY-MM''),'''|| table_name ||''');';
        CALL simple_reporting.monitored_execute(
          gen_random_uuid(),
          monitoring_key,
          target_month_date,
          call_internal_statement
        );
      END;
      $$;
    SQL
  end

  def down
    execute "DROP PROCEDURE IF EXISTS simple_reporting.add_shard_to_table"
    execute "DROP PROCEDURE IF EXISTS simple_reporting.generate_and_attach_shard_to_table"
    execute "DROP PROCEDURE IF EXISTS simple_reporting.monitored_execute"
    execute "DROP TABLE IF EXISTS simple_reporting.simple_reporting_runs"
  end
end
