require "net/http"
require "tasks/scripts/refresh_bsnl_sms_jwt"
require "tasks/scripts/get_bsnl_templates"

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
    GetBsnlTemplateDetails.new.write_to_config
  end
end
