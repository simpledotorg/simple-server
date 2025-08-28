# Root component for Dr. Rai Reports
class Dashboard::DrRaiReport < ApplicationComponent
  attr_reader :quarterlies, :region
  attr_accessor :selected_period

  def initialize(quarterlies, region_slug, selected_quarter = nil, lite = false)
    @lite = lite
    @quarterlies = quarterlies
    @region = Region.find_by(slug: region_slug)
    @selected_period = if selected_quarter.nil?
      Period.new(type: :quarter, value: current_period.value.to_s)
    else
      Period.new(type: :quarter, value: selected_quarter)
    end
  end

  def indicators
    @indicators ||= custom_indicators
  end

  def action_plans
    @action_plans ||= DrRai::ActionPlan
      .includes(:dr_rai_target)
      .where(
        region: @region,
        dr_rai_target: {period: @selected_period.value.to_s}
      )
  end

  def custom_indicators
    return nil if @lite
    return [] unless region.source_type == "Facility"
    DrRai::Indicator.all.filter do |indicator|
      indicator.is_supported?(region)
    end
  end

  def indicator_previous_numerator(indicator)
    indicator.numerator(region, selected_period.previous)
  end

  def indicator_denominator(indicator)
    indicator.denominator(region, selected_period)
  end

  def current_period
    Period.current.to_quarter_period
  end

  def current_period?
    current_period == selected_period
  end

  def start_of period
    period.begin.strftime("%b-%-d")
  end

  def end_of period
    period.end.strftime("%b-%-d")
  end

  def classes_for_period period
    raise "#{period} is not a Period" unless period.is_a? Period
    candidates = ["period-button"]
    candidates << "selected" if period == selected_period
    candidates.join(" ")
  end

  def human_readable thing
    case thing
    when Period
      human_readable_period thing
    end
  end

  def is_lite_version?
    @lite
  end

  private

  def human_readable_period period
    period.value.to_s.tr("-", " ")
  end
end
