module MonthlyIHCIReport
  class Exporter
    attr_reader :repo, :district, :month

    def initialize(district, period_month)
      @district = district
      @month = period_month
      @repo = Reports::Repository.new(district.facility_regions, periods: period_month)
    end

    def export_file
      # https://gist.github.com/aquajach/7fde54aa9bc1ac03740feb154e53eb7d
      # TODO: collate all 3 sheets into a zip file or excel sheet
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
