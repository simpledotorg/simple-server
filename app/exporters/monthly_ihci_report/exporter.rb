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
      # facility_data = FacilityData.new(district, month)
      # facility_csv = to_csv(facility_data.header_rows, facility_data.content_rows)
      # File.write("facility.csv", facility_csv)

      # block_data = BlockData.new(district, month)
      # block_csv = to_csv(block_data.header_rows, block_data.content_rows)
      # File.write("block.csv", block_csv)
    end

    def to_csv(header_rows, content_rows)
      CSV.generate(headers: true) do |csv|
        csv << [nil]

        header_rows.each do |row|
          csv << row.prepend(nil)
        end

        content_rows.each do |row|
          csv << row.values.prepend(nil)
        end
      end
    end
  end
end
