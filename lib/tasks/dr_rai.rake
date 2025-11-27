def populate_dr_rai_data(from, to, into: nil)
  raise "Must specify the Dr. Rai indicator" if into.nil?
  meta = into.to_s.downcase.split("::")
  meta.shift
  meta = meta.reverse.join(" ")
  puts "Attempting to populate Dr. Rai #{meta}"
  from_date = Date.parse(from)
  to_date = Date.parse(to)
  DrRai::DataService.populate(into, timeline: from_date..to_date)
  puts "Done populating Dr. Rai #{meta}"
end

namespace :dr_rai do
  desc "Populate Titration Data"
  task :populate_titration_data, [:from_date, :to_date] => :environment do |_, args|
    args.with_defaults(from_date: 1.year.ago.to_date.to_s, to_date: Date.today.to_s)
    populate_dr_rai_data(args[:from_date], args[:to_date], into: DrRai::Data::Titration)
  end

  desc "Populate Statins Data"
  task :populate_statins_data, [:from_date, :to_date] => :environment do |_, args|
    args.with_defaults(from_date: 1.year.ago.to_date.to_s, to_date: Date.today.to_s)
    populate_dr_rai_data(args[:from_date], args[:to_date], into: DrRai::Data::Statin)
  end

  desc "Populate BP Fudging data"
  task :populate_bp_fudging_data, [:from_date, :to_date] => :environment do |_, args|
    args.with_defaults(from_date: 1.year.ago.to_date.to_s, to_date: Date.today.to_s)
    populate_dr_rai_data(args[:from_date], args[:to_date], into: DrRai::Data::BpFudging)
  end
end
