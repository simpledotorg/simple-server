namespace :benchmark do
  desc "Benchmark materialized view refresh and store results in CSV"
  task matview_refresh: :environment do
    require "csv"
    require "benchmark"

    # Explicitly load all Report classes
    Dir[Rails.root.join("app/models/reports/*.rb")].sort.each { |file| require file }

    materialized_views = Reports::View.descendants.select(&:materialized?)

    results = []
    total_time = Benchmark.measure do
      materialized_views.each do |view_class|
        view_name = view_class.name.demodulize
        refresh_time = Benchmark.measure { view_class.refresh }

        results << {
          view: view_name,
          time: refresh_time.real
        }

        puts "Refreshed #{view_name} in #{refresh_time.real.round(2)} seconds"
      end
    end

    puts "Total refresh time: #{total_time.real.round(2)} seconds"

    csv_file = "tmp/matview_refresh_benchmark_#{Time.now.strftime("%Y%m%d_%H%M%S")}.csv"
    CSV.open(csv_file, "wb") do |csv|
      csv << ["View", "Refresh Time (seconds)"]
      results.each { |result| csv << [result[:view], result[:time].round(4)] }
      csv << ["Total", total_time.real.round(4)]
    end

    puts "Benchmark results saved to #{csv_file}"
  end
end
