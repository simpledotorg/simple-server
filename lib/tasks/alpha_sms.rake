namespace :alpha_sms do
  desc "Fetch alphasms account balance"
  task check_balance: :environment do
    response = Messaging::AlphaSms::Api.new.get_account_balance.with_indifferent_access
    expiry_date = response.dig(:data, :validity)&.to_date
    balance_amount = response.dig(:data, :balance)&.to_f

    Statsd.instance.gauge("alpha_sms_balance_bdt", balance_amount)
    Statsd.instance.gauge("alpha_sms_balance_days_till_expiry", (expiry_date - Date.current).to_i)
    Statsd.instance.flush

    print("Balance: #{balance_amount} BDT\nExpiry: #{expiry_date}")
  end
end
