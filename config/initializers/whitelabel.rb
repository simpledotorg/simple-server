Rails.application.configure do
  config.application_brand_name = ENV.fetch("APPLICATION_BRAND_NAME", "Simple")
  config.team_email_id = ENV.fetch("TEAM_EMAIL_ID", "team@simple.org")
  config.help_email_id = ENV.fetch("HELP_EMAIL_ID", "help@simple.org")
  config.cvho_email_id = ENV.fetch("CVHO_EMAIL_ID", "cvho@simple.org")
  config.eng_email_id = ENV.fetch("ENG_EMAIL_ID", "eng-backend@resolvetosavelives.org")
  config.favicon_url = ENV.fetch("FAVICON_URL", "https://simple.org/images/favicon.png")
  config.whitelabel_app = ENV["WHITELABEL_APP"] ? ActiveModel::Type::Boolean.new.cast(ENV["WHITELABEL_APP"].downcase) : false
  config.deployment_checklist_link = ENV.fetch("DEPLOYMENT_CHECKLIST_LINK", "https://docs.google.com/document/d/1cleJkm09VRGUAafkpzC9U2ao9r4r8ewZjLPwfTTj57Q/edit?usp=sharing")
  config.privacy_link = ENV.fetch("PRIVACY_LINK", "https://www.simple.org/privacy")
  config.license_link = ENV.fetch("LICENSE_LINK", "https://www.simple.org/license/")
end
