class MonthlyDistrictData::Exporter
  include MonthlyDistrictData::Utils

  attr_reader :region, :period, :months, :repo, :dashboard_analytics, :exporter

  def initialize(region, period, exporter:, medications_dispensation_enabled: false)
    @region = region
    @period = period
    @months = period.downto(5).reverse
    @medication_dispensation_months = period.downto(2).reverse
    @exporter = exporter
    regions = region.facility_regions.to_a << region
    @repo = Reports::Repository.new(regions, periods: @months)
    @medications_dispensation_enabled = medications_dispensation_enabled
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
