class Dashboard::Diabetes::DmPrescribedStatinsComponent < ApplicationComponent
  attr_reader :data, :region, :period, :with_ltfu

  def initialize(data:, region:, period:, use_who_standard:, with_ltfu: false)
    @data = data
    @region = region
    @period = period
    @with_ltfu = with_ltfu
    @use_who_standard = use_who_standard
  end

  def graph_data
    # TODO: Replace with real data once backend is ready
    {
      prescribedStatinsRate: fake_rates,
      prescribedStatinsNumerator: fake_numerators,
      adjustedPatients: fake_adjusted_patients,
      **period_data
    }
  end

  private

  def period_data
    {
      startDate: fake_period_info(:bp_control_start_date),
      endDate: fake_period_info(:bp_control_end_date),
      registrationDate: fake_period_info(:bp_control_registration_date)
    }
  end

  def fake_period_info(key)
    # Generate fake period data for the last 12 months
    (0..11).map do |i|
      period_date = period.value.advance(months: -i)
      period_key = period_date.strftime('%Y-%m')
      date_value = case key
                   when :bp_control_start_date
                     period_date.advance(months: -2).beginning_of_month.strftime('%d %b %Y')
                   when :bp_control_end_date
                     period_date.end_of_month.strftime('%d %b %Y')
                   when :bp_control_registration_date
                     period_date.advance(months: -3).end_of_month.strftime('%d %b %Y')
                   end
      [period_key, date_value]
    end.to_h
  end

  def fake_rates
    # Generate fake rates between 40-80% for the last 12 months
    (0..11).map do |i|
      period_date = period.value.advance(months: -i)
      period_key = period_date.strftime('%Y-%m')
      [period_key, rand(40.0..80.0).round(1)]
    end.to_h
  end

  def fake_numerators
    # Generate fake numerators (patients prescribed statins)
    (0..11).map do |i|
      period_date = period.value.advance(months: -i)
      period_key = period_date.strftime('%Y-%m')
      [period_key, rand(50..200)]
    end.to_h
  end

  def fake_adjusted_patients
    # Generate fake adjusted patient counts
    (0..11).map do |i|
      period_date = period.value.advance(months: -i)
      period_key = period_date.strftime('%Y-%m')
      [period_key, rand(200..500)]
    end.to_h
  end
end

