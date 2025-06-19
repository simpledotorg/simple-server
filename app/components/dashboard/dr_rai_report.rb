# Root component for Dr. Rai Reports
class Dashboard::DrRaiReport < ApplicationComponent
  # FIXME(:selected_period): Write out JS for this component's interactivity.
  # The whole current period thing only works onMount — sticking to frontend
  # terms here — after then, it's useless. This is because a view-component in
  # Rails, which this is, is technically a server-side render scoped to its own
  # local variables, and exposing methods as callable from the view. It doesn't
  # handle state.  This means interactivity cannot be handled at the view
  # component layer. In lay man's terms, when someone selects another quarter
  # to view, we need to do a full page refresh if we are depending on the view
  # component; a full page refresh passing in the selected quarter. We need JS

  attr_reader :quarterlies, :indicators
  attr_accessor :selected_period

  def initialize(quarterlies, region, selected_quarter = nil)
    @quarterlies = quarterlies
    @region = region
    @selected_period = if selected_quarter.nil?
      current_period
    else
      Period.new(type: :quarter, value: selected_quarter)
    end
    @goals = {}
    @indicators = DrRai::Indicator.where(region: Region.find_by(slug: region))
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
    candidates = ["actions-header-button"]
    candidates << "action-header-selected" if period == selected_period
    candidates.join(" ")
  end

  def period_goals
    @goals[selected_period]
  end

  def human_readable thing
    case thing
    when Period
      human_readable_period thing
    end
  end

  private

  def human_readable_period period
    period.value.to_s.tr("-", " ")
  end
end
