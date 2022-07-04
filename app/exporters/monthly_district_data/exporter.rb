class MonthlyDistrictData::Exporter
  include MonthlyDistrictData::Utils

  attr_reader :region, :period, :months, :repo, :dashboard_analytics, :exporter

  def initialize(exporter:)
    @exporter = exporter
  end

  def report
    CSV.generate(headers: true) do |csv|
      csv << ["Monthly #{localized_facility} data for #{region.name} #{period.to_date.strftime("%B %Y")}"]
      csv << exporter.section_row
      csv << exporter.sub_section_row if @medications_dispensation_enabled
      csv << exporter.header_row
      csv << exporter.district_row

      csv << [] # Empty row
      exporter.facility_size_rows.each do |row|
        csv << row
      end

      csv << [] # Empty row
      exporter.facility_rows.each do |row|
        csv << row
      end
    end
  end
end
