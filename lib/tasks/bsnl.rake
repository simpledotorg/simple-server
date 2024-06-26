require "net/http"
require "tasks/scripts/refresh_bsnl_sms_jwt"
require "tasks/scripts/get_bsnl_template_details"
require "tasks/scripts/get_bsnl_account_balance"

# Usage instructions at: doc/howto/bsnl/sms_reminders.md
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
    GetBsnlTemplateDetails.new.write_to_config
  end

  desc "List pending notification strings to be uploaded to DLT and BSNL dashboard"
  task notification_strings_summary: :environment do
    GetBsnlTemplateDetails.new.notification_strings_summary
  end

  desc "Fetch BSNL account balance"
  task get_account_balance: :environment do
    GetBsnlAccountBalance.new.print
  end

  desc "Fetch BSNL account balances and alert if we're running low or close to expiry"
  task alert_on_low_balance: :environment do
    GetBsnlAccountBalance.new.alert
  end
end
