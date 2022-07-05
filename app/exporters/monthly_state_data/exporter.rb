class MonthlyStateData::Exporter
  include MonthlyStateData::Utils

  attr_reader :region, :period, :exporter

  def initialize(exporter:)
    @exporter = exporter
    @region = @exporter.region
    @period = @exporter.period
  end

  def report
    CSV.generate(headers: true) do |csv|
      csv << ["Monthly district data for #{region.name} #{period.to_date.strftime("%B %Y")}"]
      csv << exporter.section_row
      csv << exporter.sub_section_row if @medications_dispensation_enabled
      csv << exporter.header_row
      csv << exporter.state_row
      exporter.district_rows.each do |row|
        csv << row
      end
    end
  end
end
