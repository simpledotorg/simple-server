class GetBsnlAccountBalance
  # (15_000 * 3 patients from current experiments + 15_000 patients from stale experiments) * 3 segments per message
  # We're unlikely to actually hit this number on any given day, but we'd like to alert early if we're close to the limit
  MAX_DAILY_MESSAGE_SEGMENT_COUNT = 50_000 * 3
  BALANCE_EXPIRY_ALERT_DAYS = 5

  attr_reader :recharge_details, :expiry_date, :total_balance_remaining

  def initialize
    @recharge_details = Messaging::Bsnl::Api.new.get_account_balance
    @total_balance_remaining = recharge_details.map { |recharge_detail| recharge_detail["SMS_Balance_Count"].to_i }.sum
  end

  def print
    puts recharge_details.map { |r| "#{r["SMS_Balance_Count"]} segments valid until #{r["Balance_Expiry_Time"].to_date}" }
    puts balance_expiry_message if balance_expiry_message
  end

  def alert
    raise Messaging::Bsnl::BalanceError.new(balance_expiry_message) if balance_expiry_message
  end

  private

  def balance_expiry_message
    return "Account balance is zero" if recharge_details.empty?

    expiry_date = Date.parse(recharge_details.map { |recharge| recharge["Balance_Expiry_Time"] }.max).beginning_of_day

    if expiry_date < BALANCE_EXPIRY_ALERT_DAYS.days.from_now
      "Account balance is going to expire in less than #{BALANCE_EXPIRY_ALERT_DAYS} days. Please extend validity before #{expiry_date.strftime("%d-%b-%y")}"
    elsif total_balance_remaining < (MAX_DAILY_MESSAGE_SEGMENT_COUNT * BALANCE_EXPIRY_ALERT_DAYS)
      "Account balance remaining is #{total_balance_remaining} segments, may run out in less than #{BALANCE_EXPIRY_ALERT_DAYS} days"
    end
  end
end
