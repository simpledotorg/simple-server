require "net/http"
require "tasks/scripts/refresh_bsnl_sms_jwt"
require "tasks/scripts/get_bsnl_templates"

# fix this math
MAX_DAILY_MESSAGE_COUNT = 35000 * 4
BALANCE_ALERT_DAYS = 5

# Usage instructions at: doc/howto/manage_bsnl_sms_reminders.md
namespace :bsnl do
  desc "Fetch a fresh JWT for BSNL Bulk SMS and overwrite the old token"
  task refresh_sms_jwt: :environment do
    service_id = ENV["BSNL_SERVICE_ID"]
    username = ENV["BSNL_USERNAME"]
    password = ENV["BSNL_PASSWORD"]
    token_id = ENV["BSNL_TOKEN_ID"]

    RefreshBsnlSmsJwt.new(service_id, username, password, token_id).call
  end

  desc "Get BSNL template details from the API"
  task get_template_details: :environment do
    GetBsnlTemplateDetails.new.call
  end

  desc "List pending notification strings to be uploaded to DLT and BSNL dashboard"
  task list_pending_templates: :environment do
    GetBsnlTemplateDetails.new.pending_templates
  end

  desc "Fetch BSNL account balances and alert if we're running low or close to expiry"
  task check_account_balance: :environment do
    recharge_details = Messaging::Bsnl::Api.new.get_account_balance
    total_balance_remaining = recharge_details.reduce(0) { |total, recharge| total + recharge["SMS_Balance_Count"].to_i }

    if total_balance_remaining < (MAX_DAILY_MESSAGE_COUNT * BALANCE_ALERT_DAYS)
      raise Messaging::Bsnl::Error.new("Balance is too low")
    end
  end
end
