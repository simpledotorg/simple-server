namespace :qi_reports do
  desc "Write the current country's QI report script settings as JSON to PATH (or print them)"
  task :settings, [:path] => :environment do |_task, args|
    settings = QiReport.script_settings
    abort "No QI reports script settings for #{CountryConfig.current[:name]}" if settings.blank?

    json = JSON.pretty_generate(settings)
    if args[:path].present?
      File.write(args[:path], json)
    else
      puts json
    end
  end
end
