namespace :dr_rai do
  desc "Populate Titration Data"
  task :populate_titration_data, [:from_date, :to_date] => :environment do
    args.with_defaults(from_date: 1.year.ago.to_date, to_date: Date.today)
    puts "Attempting to populate Dr. Rai titration data"
    from_date = Date.parse(args[:from_date])
    to_date = Date.parse(args[:to_date])
    DrRai::DataService.populate(DrRai::Data::Titration, from_date..to_date)
    puts "Done populating Dr. Rai Titration data"
  end
end
