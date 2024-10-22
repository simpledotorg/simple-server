namespace :benchmark do
  desc "Benchmark materialized view refresh with database reset and view alterations"
  task matview_refresh: :environment do
    puts "Starting benchmark task..."

    require "csv"
    require "benchmark"

    # Explicitly load all Report classes
    puts "Loading Report classes..."
    Dir[Rails.root.join("app/models/reports/*.rb")].sort.each { |file| require file }

    def run_benchmark
      # materialized_views = Reports::View.descendants.select { |view| view.materialized? || view.ctas_table? }
      materialized_views = [Reports::OverduePatient]
      puts "Found #{materialized_views.count} materialized views to benchmark"

      results = []
      total_time = Benchmark.measure do
        materialized_views.each do |view_class|
          view_name = view_class.name.demodulize
          puts "Benchmarking #{view_name}"
          refresh_time = Benchmark.measure { view_class.refresh }

          results << {
            view: view_name,
            time: refresh_time.real
          }

          puts "Refreshed #{view_name} in #{refresh_time.real.round(2)} seconds"
        end
      end

      puts "Total refresh time: #{total_time.real.round(2)} seconds"
      [total_time, results]
    end

    def alter_reporting_months_view(definition)
      puts "Altering reporting_months view..."
      ActiveRecord::Base.connection.execute(definition)
      puts "Finished altering reporting_months view"
    end

    def save_results(results, total_time, run_name)
      csv_file = "tmp/matview_refresh_benchmark_#{run_name}_#{Time.now.strftime("%Y%m%d_%H%M%S")}.csv"
      CSV.open(csv_file, "wb") do |csv|
        csv << ["View", "Refresh Time (seconds)"]
        results.each { |result| csv << [result[:view], result[:time].round(4)] }
        csv << ["Total", total_time.real.round(4)]
      end
      puts "Benchmark results for #{run_name} saved to #{csv_file}"
    end

    # Step 1: Drop and recreate the database
    puts "Dropping and recreating database..."
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:schema:load"].invoke
    puts "Database recreated"

    # set rails environment to development
    puts "Setting Rails environment to development..."
    Rails.env = "development"
    puts "Rails environment set to: #{Rails.env}"

    csv_files = [
      "users.csv", "organizations.csv", "facility_groups.csv", "facilities.csv",
      "regions.csv", "addresses.csv", "patients.csv", "patient_phone_numbers.csv",
      "encounters.csv", "blood_pressures.csv", "blood_sugars.csv", "observations.csv",
      "prescription_drugs.csv", "appointments.csv", "medical_histories.csv"
    ]

    puts "Importing CSV files..."
    csv_files.each do |csv_file|
      puts "Importing #{csv_file}..."
      system("psql", "-d", ActiveRecord::Base.connection_db_config.database, "-c", "\\copy #{File.basename(csv_file, ".csv")} from '#{Rails.root.join("bdsmall", csv_file)}' csv header")
    end
    puts "Finished importing CSV files"

    puts "Initial refresh of all materialized views with concurrent refresh disabled..."
    ENV["REFRESH_MATVIEWS_CONCURRENTLY"] = "false"
    ENV["CTAS"] = "false"
    puts ENV["REFRESH_MATVIEWS_CONCURRENTLY"], ENV["CTAS"]
    ENV["NO_MATVIEW"] = "false"
    Rake::Task["db:refresh_reporting_views"].invoke
    ENV["NO_MATVIEW"] = "true"
    ENV["CTAS"] = "true"
    ENV["REFRESH_MATVIEWS_CONCURRENTLY"] = "true"
    puts ENV["REFRESH_MATVIEWS_CONCURRENTLY"], ENV["CTAS"]

    # Step 2: Alter the reporting_months view (first alteration)
    puts "Performing first alteration of reporting_months view..."
    alter_reporting_months_view(<<-SQL)
      CREATE OR REPLACE VIEW reporting_months AS
       WITH month_dates AS (
         SELECT date(generate_series.generate_series) AS month_date
           FROM generate_series(('2018-01-01'::date)::timestamp with time zone, ('2024-07-01'::date)::timestamp with time zone, '1 mon'::interval) generate_series(generate_series)
        )
        SELECT month_dates.month_date,
          date_part('month'::text, month_dates.month_date) AS month,
          date_part('quarter'::text, month_dates.month_date) AS quarter,
          date_part('year'::text, month_dates.month_date) AS year,
          to_char((month_dates.month_date)::timestamp with time zone, 'YYYY-MM'::text) AS month_string,
          to_char((month_dates.month_date)::timestamp with time zone, 'YYYY-Q'::text) AS quarter_string
        FROM month_dates;
    SQL

    # Step 3: Run the benchmarks
    puts "Running first benchmark..."
    first_run_time, first_run_results = run_benchmark
    save_results(first_run_results, first_run_time, "FirstRun")

    # Step 4: Alter the reporting_months view again
    puts "Performing second alteration of reporting_months view..."
    alter_reporting_months_view(<<-SQL)
      CREATE OR REPLACE VIEW reporting_months AS
       WITH month_dates AS (
         SELECT date(generate_series.generate_series) AS month_date
           FROM generate_series(('2018-01-01'::date)::timestamp with time zone, ('2024-08-01'::date)::timestamp with time zone, '1 mon'::interval) generate_series(generate_series)
        )
        SELECT month_dates.month_date,
          date_part('month'::text, month_dates.month_date) AS month,
          date_part('quarter'::text, month_dates.month_date) AS quarter,
          date_part('year'::text, month_dates.month_date) AS year,
          to_char((month_dates.month_date)::timestamp with time zone, 'YYYY-MM'::text) AS month_string,
          to_char((month_dates.month_date)::timestamp with time zone, 'YYYY-Q'::text) AS quarter_string
        FROM month_dates;
    SQL

    # Step 5: Rerun the benchmark
    puts "Running second benchmark..."
    second_run_time, second_run_results = run_benchmark
    save_results(second_run_results, second_run_time, "SecondRun")

    # Step 6: Run Vacuum
    puts "Running VACUUM ANALYZE..."
    ActiveRecord::Base.connection.execute("VACUUM ANALYZE")

    puts "Benchmark completed. Results saved in separate CSV files."
  end
end
