# frozen_string_literal: true

# A QI report PDF produced by send_district_reports.py. Files live in storage/qi_reports (not
# public/, which is served without a login) and are named "<Report> - <District> - <Mon YYYY>.pdf"
# (or "<Report> - <District> - YYYY-MM-DD.pdf" for month-to-date runs).
class QiReport
  DIRECTORY = Rails.root.join("storage", "qi_reports")
  FILENAME = /\A(?<report>.+?) - (?<district>.+) - (?<period>[A-Za-z]{3} \d{4}|\d{4}-\d{2}-\d{2})\.pdf\z/

  attr_reader :filename, :report, :district, :period

  def self.all
    return [] unless DIRECTORY.directory?
    Dir.children(DIRECTORY).filter_map { |name| parse(name) }.sort_by { |r| [r.district, r.report, r.sort_date.to_s] }
  end

  # Reports the user may see: the PDF's district must be one the user can view reports for.
  # Files whose district doesn't match a known district are hidden (except for power users).
  def self.visible_to(user)
    return all if user.power_user?
    districts = user.accessible_district_regions(:view_reports).pluck(:name).map(&:downcase).to_set
    all.select { |r| districts.include?(r.district.downcase) }
  end

  def self.parse(name)
    match = FILENAME.match(name)
    new(name, match[:report], match[:district], match[:period]) if match
  end

  def initialize(filename, report, district, period)
    @filename, @report, @district, @period = filename, report, district, period
  end

  def path
    DIRECTORY.join(filename)
  end

  def label
    "#{district} · #{report} · #{period}"
  end

  def sort_date
    Date.parse(period)
  rescue ArgumentError
    nil
  end
end
