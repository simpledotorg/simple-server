namespace :cohort_reports do
  desc 'Generate cohort report CSV for each state'
  task :generate, [:year, :quarter, :organization_name] => :environment do |_t, args|
    abort 'Requires [year, quarter] arguments' unless args[:year].present? && args[:quarter].present?
    abort 'Requires [organization_name]' unless args[:organization_name].present?

    year    = args[:year].to_i
    quarter = args[:quarter].to_i
    organization_name = args[:organization_name]

    states = Organization.find_by(name: organization_name).facilities.pluck(:state).uniq

    states.each do |state|
      file = File.join(Dir.home, "#{year}-q#{quarter}-#{state.downcase}.csv")

      facilities = Facility.where(state: state)

      headers = [
        "Facility", "Type", "District", "State",
        "Registered", "Followed Up", "Controlled", "Uncontrolled", "Defaulted",
      ]

      puts "Generating CSV for #{state}, Q#{quarter} #{year}"

      CSV.open(file, "w", write_headers: true, headers: headers) do |csv|
        facilities.sort_by { |f| [f.state, f.district, f.name] }.each do |facility|
          query = CohortAnalyticsQuery.new(facility.registered_patients)

          # 3-6 month cohort
          patient_counts = query.patient_counts(year: year, quarter: quarter)

          csv << [
            facility.name.strip, facility.facility_type.strip, facility.district.strip, facility.state.strip,
            *patient_counts.values_at(:registered, :followed_up, :controlled, :uncontrolled, :defaulted)
          ]
        end
      end
    end
  end
end
