class GetBsnlAccountBalance
  # (20_000 * 3 patients from current experiments + 15_000 patients from stale experiments) * 4 segments per message
  # We're unlikely to actually hit this number on any given day, but we'd like to alert early if we're close to the limit
  MAX_DAILY_MESSAGE_SEGMENT_COUNT = 75_000 * 4
  BALANCE_EXPIRY_ALERT_DAYS = 3

  class BalanceError < StandardError
  end

  attr_reader :recharge_details, :expiry_date, :total_balance_remaining

  def initialize
    @recharge_details = Messaging::Bsnl::Api.new.get_account_balance
    @expiry_date = Date.parse(recharge_details.map { |recharge| recharge["Balance_Expiry_Time"] }.max).beginning_of_day
    @total_balance_remaining = recharge_details.reduce(0) { |total, recharge| total + recharge["SMS_Balance_Count"].to_i }
  end

  def call
    if expiry_date < BALANCE_EXPIRY_ALERT_DAYS.days.from_now
      raise BalanceError.new("Account balance is going to expire in less than #{BALANCE_EXPIRY_ALERT_DAYS} days. Please extend validity before #{expiry_date.strftime("%d-%b-%y")}")
    end

    if total_balance_remaining < (MAX_DAILY_MESSAGE_SEGMENT_COUNT * BALANCE_EXPIRY_ALERT_DAYS)
      raise BalanceError.new("Account balance remaining is #{total_balance_remaining} segments, may run out in less than #{BALANCE_EXPIRY_ALERT_DAYS} days")
    end
  end
end
