class MonthlyStateData::Exporter
  include MonthlyStateData::Utils
  attr_reader :region, :period, :months, :medications_dispensation_enabled, :medications_dispensation_months, :repo

  def initialize(region:, period:, medications_dispensation_enabled: false)
    @region = region
    @period = period
    @months = period.downto(5).reverse
    @medications_dispensation_months = period.downto(2).reverse
    regions = region.district_regions.to_a << region
    @repo = Reports::Repository.new(regions, periods: @months)
    @medications_dispensation_enabled = medications_dispensation_enabled
  end

  def report
    CSV.generate(headers: true) do |csv|
      csv << ["Monthly district data for #{region.name} #{period.to_date.strftime("%B %Y")}"]
      csv << section_row
      csv << sub_section_row if medications_dispensation_enabled
      csv << header_row
      csv << state_row
      district_rows.each do |row|
        csv << row
      end
    end
  end

  def section_row
    raise NotImplementedError
  end

  def sub_section_row
    raise NotImplementedError
  end

  def header_row
    raise NotImplementedError
  end

  def state_row
    raise NotImplementedError
  end

  def district_rows
    raise NotImplementedError
  end
end
