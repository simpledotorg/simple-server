require "net/http"

namespace :alpha_sms do
  desc "Fetch account balance and alert if we're running low or close to expiry"
  task alert_on_low_balance: :environment do
    max_cost_per_day = 5000
    alert_in_days = 5

    response = Messaging::AlphaSms::Api.new
      .get_account_balance
      .with_indifferent_access
    expiry_date = response.dig(:data, :validity)&.to_date
    balance_amount = response.dig(:data, :balance)&.to_f

    if expiry_date < alert_in_days.from.now
      Rails.logger.error("Account balance expires in less than #{alert_in_days}. Please recharge before #{expiry_date}.")
    elsif balance_amount < (alert_in_days * max_cost_per_day)
      Rails.logger.error("Remaining account balance is #{balance_amount} BDT. May expire in less than #{alert_in_days} days.")
    end
  end
end
