module MonthlyIHCIReport
  class Exporter
    attr_reader :repo, :district, :month

    def initialize(district, period_month)
      @district = district
      @month = period_month
      @repo = Reports::Repository.new(district.facility_regions, periods: period_month)
    end

    def dev_stuff
      # TODO: remove this when you don't need it anymore
      reload!
      r = Region.find_by(id: "3de010c5-bb42-4835-9cdd-fbaa6aee08d5")
      p = Period.month("2021-09-01".to_date)
      file_content = MonthlyIHCIReport::Exporter.new(r, p).export_file
      File.write("foo.csv", file_content)
    end

    def export_file
      # https://gist.github.com/aquajach/7fde54aa9bc1ac03740feb154e53eb7d
      to_csv(FacilityData.new(district, month).rows)
    end

    def to_csv(rows)
      csv_data = rows
      headers = csv_data.first.keys
      CSV.generate(headers: true) do |csv|
        csv << [nil]
        csv << headers.prepend(nil)

        csv_data.each do |row|
          csv << row.values.prepend(nil)
        end
      end
    end
  end
end
