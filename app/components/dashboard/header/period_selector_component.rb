class Dashboard::Header::PeriodSelectorComponent < ApplicationComponent
  attr_reader :current_period

  def initialize(current_period:, with_ltfu:)
    @current_period = current_period
    @with_ltfu = with_ltfu
  end

  def periods
    (0..5).map do |num|
      Period.new(
        type: :month,
        value: Date.current.beginning_of_month.advance(months: -num)
      )
    end
  end
end
