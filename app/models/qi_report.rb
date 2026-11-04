# frozen_string_literal: true

# A QI report PDF produced by script/qi_reports/publish_district_reports.py. Files live in storage/qi_reports (not
# public/, which is served without a login) and are named "<Report> - <District> - <Mon YYYY>.pdf"
# (or "<Report> - <District> - YYYY-MM-DD.pdf" for month-to-date runs).
class QiReport
  DIRECTORY = Rails.root.join("storage", "qi_reports")
  FILENAME = /\A(?<report>.+?) - (?<district>.+) - (?<period>[A-Za-z]{3} \d{4}|\d{4}-\d{2}-\d{2})\.pdf\z/

  # Per-country settings (CountryConfig[:qi_reports]): whether the QI reports tab is switched on (off
  # unless a country sets enabled: true), the level the reports are written for, and the labels for the
  # dropdowns. "district" reports sit under a division/state; "state" reports are one
  # per state region (for example Ethiopia's regions) and are matched to state regions.
  DEFAULT_SETTINGS = {enabled: false, level: "district", division_label: "Division", place_label: "District"}.freeze

  attr_reader :filename, :report, :district, :period

  def self.settings
    # CountryConfig stores nested settings with string keys (it is a HashWithIndifferentAccess), so
    # symbolize them before merging over the symbol-keyed defaults
    DEFAULT_SETTINGS.merge((CountryConfig.current[:qi_reports] || {}).to_h.symbolize_keys.except(:script))
  end

  # Settings for script/qi_reports/publish_district_reports.py (Metabase questions, filter names,
  # wording, ...), written out as JSON by `rails qi_reports:settings`. nil if the country has none.
  def self.script_settings
    CountryConfig.current.dig(:qi_reports, :script)&.to_h
  end

  def self.enabled?
    settings[:enabled] == true
  end

  def self.state_level?
    settings[:level].to_s == "state"
  end

  def self.all
    return [] unless DIRECTORY.directory?
    Dir.children(DIRECTORY).filter_map { |name| parse(name) }.sort_by { |r| [r.district, r.report, r.sort_date.to_s] }
  end

  # Reports the user may see: the PDF's district (or state region, for state-level countries) must be
  # one the user can view reports for. Files that match no known place are hidden (except for power
  # users). Only the configured level is matched, so a state and a district with the same name can't
  # expose each other's reports.
  def self.visible_to(user)
    return all if user.power_user?
    # accessible_state_regions is only on UserAccess (User delegates the district-level methods)
    regions = state_level? ? user.user_access.accessible_state_regions(:view_reports) : user.accessible_district_regions(:view_reports)
    names = regions.pluck(:name).map(&:downcase).to_set
    all.select { |r| names.include?(r.district.downcase) }
  end

  # District name (downcased) => the division (state region) it belongs to, for the districts the
  # user can view reports for.
  def self.divisions_by_district(user)
    regions = user.power_user? ? Region.district_regions : user.accessible_district_regions(:view_reports)
    regions.each_with_object({}) { |region, map| map[region.name.downcase] = region.state_region&.name }
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
