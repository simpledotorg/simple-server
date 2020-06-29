namespace :cohort_reports do
  desc "Generate cohort report CSV for each state"
  task :generate, [:year, :quarter, :organization_name] => :environment do |_t, args|
    include QuarterHelper

    abort "Requires [year, quarter] arguments" unless args[:year].present? && args[:quarter].present?
    abort "Requires [organization_name]" unless args[:organization_name].present?

    year = args[:year].to_i
    quarter = args[:quarter].to_i
    organization_name = args[:organization_name]

    Time.zone = "Asia/Kolkata"

    report_start = quarter_start(year, quarter)
    report_end = report_start.end_of_quarter
    cohort_start = (report_start - 3.months).beginning_of_quarter
    cohort_end = cohort_start.end_of_quarter

    organization = Organization.find_by(name: organization_name)
    states = organization.facilities.pluck(:state).uniq

    states.each do |state|
      file = File.join(Dir.home, "#{year}-q#{quarter}-#{state.downcase}.csv")

      facilities = organization.facilities.where(state: state).order(:district, :name)

      headers = [
        "Facility", "Type", "District", "State",
        "Registered", "Followed Up", "Controlled", "Uncontrolled", "Defaulted"
      ]

      puts "Generating CSV for #{state}, Q#{quarter} #{year}"

      CSV.open(file, "w", write_headers: true, headers: headers) do |csv|
        facilities.sort_by { |f| [f.state, f.district, f.name] }.each do |facility|
          query = CohortAnalyticsQuery.new(facility.registered_patients)

          # 3-6 month cohort
          patient_counts = query.patient_counts(cohort_start, cohort_end, report_start, report_end)

          csv << [
            facility.name.strip, facility.facility_type.strip, facility.district.strip, facility.state.strip,
            *patient_counts.values_at(:registered, :followed_up, :controlled, :uncontrolled, :defaulted)
          ]
        end
      end
    end
  end
end
